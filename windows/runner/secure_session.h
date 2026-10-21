#ifndef FRUITOPIA_SECURE_SESSION_H_
#define FRUITOPIA_SECURE_SESSION_H_
#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>
#include <memory>

std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
CreateSecureSessionChannel(flutter::BinaryMessenger* messenger);
#endif
