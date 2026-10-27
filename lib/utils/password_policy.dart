import 'dart:convert';

bool acceptsNewPassword(String value) =>
    value.trim().isNotEmpty && utf8.encode(value).length <= 72;

const passwordPolicyError = 'password_must_not_be_blank_max_72_bytes';
