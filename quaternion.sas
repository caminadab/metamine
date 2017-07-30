complex = re + im*i

c: complex
c = 3 + 2*i


quaternion :: R^4
	w,x,y,z = self

a = 10

a * b =
	a: quaternion
	b: quaternion
	c: quaternion

	c.w = (a.w * b.w) - (a.x * b.x) - (a.y * b.y) - (a.z * b.z)
	c.x = (a.x * b.w) + (a.w * b.x) + (a.z * b.y) - (a.y * b.z)
	c.y = (a.y * b.w) + (a.w * b.y) + (a.x * b.z) - (a.z * b.x)
	c.z = (a.z * b.w) + (a.w * b.z) + (a.y * b.x) - (a.x * b.y)
	c
	

(a: quaternion * b: quaternion): quaternion = (
	(a.w * b.w) - (a.x * b.x) - (a.y * b.y) - (a.z * b.z),
	(a.x * b.w) + (a.w * b.x) + (a.z * b.y) - (a.y * b.z),
	(a.y * b.w) + (a.w * b.y) + (a.x * b.z) - (a.z * b.x),
	(a.z * b.w) + (a.w * b.z) + (a.y * b.x) - (a.x * b.y)
)
