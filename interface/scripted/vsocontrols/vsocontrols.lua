vso = "error"

function init()
  vso = pane.sourceEntity() or "error" -- can't be nil because lounging in nothing is also nil
  widget.focus("input")
end

function keyEvent(key, isKeyDown)
  if key == 3 -- enter
  or key == 19 -- /
  then -- escape closes it too
    pane.dismiss()
  else
    world.sendEntityMessage(vso, "keyEvent", key, isKeyDown)
  end
end

function update()
  if player.loungingIn() ~= vso then
    pane.dismiss()
  else
    widget.focus("input")
  end
end