# System memory: Bind Manager and HUD

`bind_service.lua` version 1 is the only key-input router. General and game-package views register metadata; they never open their own `InputBegan` listener for key activation.

## Contract

- Every target has a stable `Id`, `Scope`, `Kind` (`Toggle` or `Action`), central `IconKey`, inactive/active color token, optional real cooldown, availability callback, and existing controller action.
- The global maximum is five assignments across general and game scopes. Keys and target IDs must both be unique. A sixth assignment or duplicate/reserved key is rejected without changing the prior assignment.
- `Escape` cancels capture; `Backspace` clears it. Processed input and focused text/chat boxes are ignored during both capture and activation.
- Game views unregister their descriptors during destroy. Unregister clears the live assignment, cooldown, HUD record, and persisted runtime order.

## HUD

- One loader-owned `BindHUD` lives at right-center. It is hidden until the approved loader has completely exited and is destroyed on unload.
- Each assignment creates one 56×56 icon with 12 px visible spacing (`68` px center step). One icon is centered; two through five are symmetrically recentered on the same X line in assignment order.
- Z-index 1500 places the HUD above cheat overlays and below TasuHub windows (2000+).
- Toggle state changes icon opacity/tint. Press uses one short shrink/overshoot/settle sequence. MM2 `Pick Up Gun`, `Shoot Now`, `Auto Fire`, and `Auto Pickup` use central icon keys; no feature file contains a direct asset ID.
- Real action cooldowns share one scheduler. A gray mask begins full and recedes toward the bottom, revealing the PNG from top to bottom. The scheduler disconnects when empty and the final frame sets mask size to zero without refill flicker.

## Capture feedback

- Rejection temporarily displays the attempted key in `Danger`, shakes horizontally, then restores the prior key and normal color.
- Success changes the accepted key from white to `Success`, grows/settles the control, then restores normal white.
- Bind icons are configured through `UI.AssetManifest.BindHUD`, `SetBindIcon`, or exported `env.TasuHub.SetBindIcon`. Resolver input accepts numeric Roblox IDs, `rbxassetid://`, built-in `rbxasset://`, and HTTPS executor-cached PNG sources.

Executor checks: all duplicate/reserved/limit paths, processed input, chat focus, Escape, Backspace, one-to-five alignment, game unload removal, cooldown final frame, config order restore, reload, and hub unload.
