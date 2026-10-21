#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>

#include "app_links/app_links_plugin_c_api.h"
#include "flutter_window.h"
#include "utils.h"

namespace {
void RegisterAuthRedirectProtocol() {
  wchar_t executablePath[32768] = {};
  const DWORD pathLength =
      GetModuleFileNameW(nullptr, executablePath, ARRAYSIZE(executablePath));
  if (pathLength == 0 || pathLength >= ARRAYSIZE(executablePath)) return;

  constexpr wchar_t kProtocolKey[] =
      L"Software\\Classes\\com.example.traicay";
  HKEY protocolKey = nullptr;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kProtocolKey, 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr,
                      &protocolKey, nullptr) != ERROR_SUCCESS) {
    return;
  }
  const wchar_t emptyValue[] = L"";
  RegSetValueExW(protocolKey, L"URL Protocol", 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(emptyValue), sizeof(emptyValue));
  RegCloseKey(protocolKey);

  HKEY commandKey = nullptr;
  constexpr wchar_t kCommandKey[] =
      L"Software\\Classes\\com.example.traicay\\shell\\open\\command";
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kCommandKey, 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_WRITE, nullptr,
                      &commandKey, nullptr) != ERROR_SUCCESS) {
    return;
  }
  std::wstring command = L"\"" + std::wstring(executablePath, pathLength) +
                         L"\" \"%1\"";
  RegSetValueExW(commandKey, nullptr, 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(command.c_str()),
                 static_cast<DWORD>((command.size() + 1) * sizeof(wchar_t)));
  RegCloseKey(commandKey);
}
}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Forward OAuth callbacks to the already-running app when possible.
  if (SendAppLinkToInstance()) {
    return EXIT_SUCCESS;
  }
  RegisterAuthRedirectProtocol();

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"traicay", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
