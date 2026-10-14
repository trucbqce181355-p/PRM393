#include "secure_session.h"
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <wincred.h>
#include <string>

std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
CreateSecureSessionChannel(flutter::BinaryMessenger* messenger) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "fruitopia/secure_session", &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler([](const auto& call, auto result) {
    const wchar_t* target = L"Fruitopia/AuthSession/v1";
    if (call.method_name() == "read") {
      PCREDENTIALW credential = nullptr;
      if (!CredReadW(target, CRED_TYPE_GENERIC, 0, &credential)) {
        if (GetLastError() == ERROR_NOT_FOUND) { result->Success(); return; }
        result->Error("credential_read", "Cannot read Windows credential."); return;
      }
      if (!credential->CredentialBlob || credential->CredentialBlobSize == 0 || credential->CredentialBlobSize > 256) {
        CredFree(credential);
        result->Error("credential_read", "Stored credential is invalid."); return;
      }
      std::string token(reinterpret_cast<char*>(credential->CredentialBlob),
                        credential->CredentialBlobSize);
      SecureZeroMemory(credential->CredentialBlob, credential->CredentialBlobSize);
      CredFree(credential);
      result->Success(flutter::EncodableValue(token));
    } else if (call.method_name() == "write") {
      const auto* args = call.arguments() ? std::get_if<flutter::EncodableMap>(call.arguments()) : nullptr;
      if (!args) { result->Error("credential_argument", "Missing token."); return; }
      const auto entry = args->find(flutter::EncodableValue("token"));
      const auto* token = entry != args->end() ? std::get_if<std::string>(&entry->second) : nullptr;
      if (!token || token->empty() || token->size() > 256) {
        result->Error("credential_argument", "Invalid token."); return;
      }
      CREDENTIALW credential = {};
      credential.Type = CRED_TYPE_GENERIC;
      credential.TargetName = const_cast<wchar_t*>(target);
      credential.UserName = const_cast<wchar_t*>(L"Fruitopia");
      credential.CredentialBlobSize = static_cast<DWORD>(token->size());
      credential.CredentialBlob = reinterpret_cast<LPBYTE>(const_cast<char*>(token->data()));
      credential.Persist = CRED_PERSIST_LOCAL_MACHINE;
      if (!CredWriteW(&credential, 0)) {
        result->Error("credential_write", "Cannot store Windows credential."); return;
      }
      result->Success();
    } else if (call.method_name() == "delete") {
      if (!CredDeleteW(target, CRED_TYPE_GENERIC, 0) && GetLastError() != ERROR_NOT_FOUND) {
        result->Error("credential_delete", "Cannot delete Windows credential."); return;
      }
      result->Success();
    } else {
      result->NotImplemented();
    }
  });
  return channel;
}
