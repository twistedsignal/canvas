-- a vide source that changes whenever an instance's properties or children change, so derived
-- values (current AnchorPoint, whether it has a UICorner, ...) stay in sync with edits made
-- anywhere in Studio. call inside a vide scope.
const vide = require("./vide")

const function Watch(target: () -> Instance?): () -> number
	const version = vide.source(0)
	vide.effect(function()
		const instance = target()
		if not instance then
			return
		end
		const function bump()
			version(version() + 1)
		end
		const connections = {
			instance.Changed:Connect(bump),
			instance.ChildAdded:Connect(bump),
			instance.ChildRemoved:Connect(bump),
		}
		vide.cleanup(function()
			for _, connection in connections do
				connection:Disconnect()
			end
		end)
	end)
	return version
end

return Watch
