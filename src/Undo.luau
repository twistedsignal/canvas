-- wraps an edit in one ChangeHistoryService recording so Ctrl+Z undoes all of it.
const ChangeHistoryService = game:GetService("ChangeHistoryService")

const Undo = {}

function Undo.record(name: string, edit: () -> ())
	const id = ChangeHistoryService:TryBeginRecording(`Canvas: {name}`)
	const ok, err = pcall(edit)
	if id then
		ChangeHistoryService:FinishRecording(
			id,
			if ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
		)
	end
	if not ok then
		warn(`Canvas: {name} failed: {err}`)
	end
end

-- starts a recording that stays open across many changes, like dragging in a color picker.
-- call the returned function once to commit it.
function Undo.begin(name: string): () -> ()
	const id = ChangeHistoryService:TryBeginRecording(`Canvas: {name}`)
	local finished = false
	return function()
		if finished then
			return
		end
		finished = true
		if id then
			ChangeHistoryService:FinishRecording(id, Enum.FinishRecordingOperation.Commit)
		end
	end
end

return Undo
