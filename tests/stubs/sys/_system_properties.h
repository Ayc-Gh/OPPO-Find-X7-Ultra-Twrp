#pragma once
#include <string>
struct prop_info { std::string value; };
const prop_info* __system_property_find(const char*);
int __system_property_update(prop_info*, const char*, unsigned int);
int __system_property_add(const char*, unsigned int, const char*, unsigned int);
