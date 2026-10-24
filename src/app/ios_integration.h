// Aseprite
// Copyright (C) 2026  Emir Yaman Sivrikaya
//
// This program is distributed under the terms of
// the End-User License Agreement for Aseprite.

#ifndef APP_IOS_INTEGRATION_H_INCLUDED
#define APP_IOS_INTEGRATION_H_INCLUDED
#pragma once

namespace app {

// Connects iPadOS specific gestures (two/three-finger taps, Apple
// Pencil double-tap/squeeze) and life-cycle events to the app.
void init_ios_integration();

} // namespace app

#endif
