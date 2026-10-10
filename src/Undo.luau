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

return Undo
