// Aseprite
// Copyright (C) 2026  Emir Yaman Sivrikaya
//
// This program is distributed under the terms of
// the End-User License Agreement for Aseprite.

#ifdef HAVE_CONFIG_H
  #include "config.h"
#endif

#include "app/ios_integration.h"

#include "app/app.h"
#include "app/commands/command.h"
#include "app/commands/commands.h"
#include "app/pref/preferences.h"
#include "app/tools/active_tool.h"
#include "app/tools/tool.h"
#include "app/tools/tool_box.h"
#include "app/ui/toolbar.h"
#include "app/ui_context.h"
#include "os/ios/system.h"

#include <string>

namespace app {

namespace {

// Tool selected before switching to the eraser with the Apple Pencil
std::string g_toolBeforeEraser;

void execute_command(const char* id)
{
  if (Command* cmd = Commands::instance()->byId(id))
    UIContext::instance()->executeCommandFromMenuOrShortcut(cmd);
}

void toggle_eraser()
{
  App* app = App::instance();
  ToolBar* toolbar = ToolBar::instance();
  if (!app || !toolbar)
    return;

  tools::ToolBox* toolbox = app->toolBox();
  tools::Tool* current = app->activeToolManager()->selectedTool();
  if (!current)
    return;

  if (current->getId() == tools::WellKnownTools::Eraser) {
    tools::Tool* prev = toolbox->getToolById(g_toolBeforeEraser.empty() ?
                                               tools::WellKnownTools::Pencil :
                                               g_toolBeforeEraser);
    if (prev)
      toolbar->selectTool(prev);
  }
  else if (tools::Tool* eraser = toolbox->getToolById(tools::WellKnownTools::Eraser)) {
    g_toolBeforeEraser = current->getId();
    toolbar->selectTool(eraser);
  }
}

} // anonymous namespace

void init_ios_integration()
{
  os::ios_set_gesture_handler([](os::IOSGesture gesture) {
    switch (gesture) {
      case os::IOSGesture::Undo:            execute_command(CommandId::Undo()); break;
      case os::IOSGesture::Redo:            execute_command(CommandId::Redo()); break;
      case os::IOSGesture::PencilDoubleTap: toggle_eraser(); break;
      case os::IOSGesture::PencilSqueeze:   execute_command(CommandId::SwitchColors()); break;
    }
  });

  // iOS can kill the app while it's in background, so we save the
  // preferences each time the app goes to background.
  os::ios_set_background_handler([] { Preferences::instance().save(); });
}

} // namespace app
