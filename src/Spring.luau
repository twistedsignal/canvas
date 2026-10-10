-- a damped spring for Vector2 values. step it every frame with the frame's delta time.
-- frequency is in cycles per second; damping 1 is critical, lower values overshoot.
const Spring = {}
Spring.__index = Spring

export type Spring = typeof(setmetatable(
	{} :: {
		position: Vector2,
		velocity: Vector2,
		goal: Vector2,
		frequency: number,
		damping: number,
	},
	Spring
))

const MAX_STEP = 1 / 240
const EPSILON = 0.01

function Spring.new(value: Vector2, frequency: number, damping: number): Spring
	return setmetatable({
		position = value,
		velocity = Vector2.zero,
		goal = value,
		frequency = frequency,
		damping = damping,
	}, Spring)
end

function Spring.target(self: Spring, goal: Vector2)
	self.goal = goal
end

-- jump straight to a value with no motion.
function Spring.snap(self: Spring, value: Vector2)
	self.position = value
	self.goal = value
	self.velocity = Vector2.zero
end

function Spring.impulse(self: Spring, velocity: Vector2)
	self.velocity += velocity
end

function Spring.settled(self: Spring): boolean
	return (self.position - self.goal).Magnitude < EPSILON and self.velocity.Magnitude < EPSILON
end

-- advances the spring. returns true while it's still moving.
function Spring.step(self: Spring, dt: number): boolean
	if self:settled() then
		self.position = self.goal
		self.velocity = Vector2.zero
		return false
	end
	const omega = 2 * math.pi * self.frequency
	local remaining = math.min(dt, 0.1)
	while remaining > 0 do
		const h = math.min(remaining, MAX_STEP)
		const acceleration = (self.goal - self.position) * (omega * omega) - self.velocity * (2 * self.damping * omega)
		self.velocity += acceleration * h
		self.position += self.velocity * h
		remaining -= h
	end
	return true
end

return Spring
