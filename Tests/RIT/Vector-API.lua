local vectorAPI = System.GetAPI("vector")



function Test_Add()
	local vector = vectorAPI.New(4,2,6)
	local actual = vector + vector
	local expected = vectorAPI.New(8,4,12)


	print("\nTest_Add():\n", assert(actual == expected, "Actual: " .. actual:ToString() .. " - Expected: " .. expected:ToString()))
end

function Test_Subtract()
	local vector = vectorAPI.New(4,2,6)
	local vector2 = vectorAPI.New(2,3,2)
	local actual = vector - vector2
	local expected = vectorAPI.New(2,-1,4)

	print("\nTest_Subtract():\n", assert(actual == expected, "Actual: " .. actual:ToString() .. " - Expected: " .. expected:ToString()))
end

function Test_Multiply()
	local vector = vectorAPI.New(4, 2, 6)
	local actual = vector * 2
	local expected = vectorAPI.New(8, 4, 12)

	print("\nTest_Multiply():\n", assert(actual == expected, "Actual: " .. actual:ToString() .. " - Expected: " .. expected:ToString()))
end

function Test_Divide()
	local vector = vectorAPI.New(4, 2, 6)
	local actual = vector / 2
	local expected = vectorAPI.New(2, 1, 3)

	print("\nTest_Divide():\n", assert(actual == expected, "Actual: " .. actual:ToString() .. " - Expected: " .. expected:ToString()))
end

function Test_Negate()
	local vector = vectorAPI.New(4, 2, 6)
	local actual = -vector
	local expected = vectorAPI.New(-4, -2, -6)

	print("\nTest_Negate():\n", assert(actual == expected, "Actual: " .. actual:ToString() .. " - Expected: " .. expected:ToString()))
end

function Test_Dot()
	local vector1 = vectorAPI.New(4, 2, 6)
	local vector2 = vectorAPI.New(2, 3, 2)
	local actual = vector1:Dot(vector2)
	local expected = 26

	print("\nTest_Dot():\n", assert(actual == expected, "Actual: " .. actual .. " - Expected: " .. expected))
end

function Test_Cross()
	local vector1 = vectorAPI.New(4, 2, 6)
	local vector2 = vectorAPI.New(2, 3, 2)
	local actual = vector1:Cross(vector2)
	local expected = vectorAPI.New(-14, 4, 8)

	print("\nTest_Cross():\n", assert(actual == expected, "Actual: " .. actual:ToString() .. " - Expected: " .. expected:ToString()))
end

function Test_Length()
	local vector = vectorAPI.New(4, 2, 6)
	local actual = vector:Length()
	local expected = math.sqrt(4*4 + 2*2 + 6*6)

	print("\nTest_Length():\n", assert(actual == expected, "Actual: " .. actual .. " - Expected: " .. expected))
end

function Test_Normalize()
	local vector = vectorAPI.New(4, 2, 6)
	local actual = vector:Normalize()
	local magnitude = 1/vector:Length()
	local expected = vectorAPI.New(4*magnitude, 2*magnitude, 6*magnitude)

	print("\nTest_Normalize():\n", assert(actual == expected, "Actual: " .. actual:ToString() .. " - Expected: " .. expected:ToString()))
end

function Test_Project()
    local vector1 = vectorAPI.New(4, 2, 6)
    local vector2 = vectorAPI.New(2, 3, 8)
    local actual = vector1:Project(vector2)
    local actualRounded = actual:Round(0.000000000001) -- Reaching the limits of LUA and floats here
    local expected = vectorAPI.New(124/77,186/77,496/77)
    local expectedRounded = actual:Round(0.000000000001)
    
    print("\nTest_Project():\n ", assert(actualRounded == expectedRounded, "Actual: " .. actualRounded:ToString() .. " - Expected: " .. expectedRounded:ToString()))
end


function Test_Round()
	local vector = vectorAPI.New(4.5, 2.3, 6.7)
	local actual = vector:Round()
	local expected = vectorAPI.New(5, 2, 7)

	print("\nTest_Round():\n", assert(actual == expected, "Actual: " .. actual:ToString() .. " - Expected: " .. expected:ToString()))
end

function Test_Equals()
	local vector1 = vectorAPI.New(4, 2, 6)
	local vector2 = vectorAPI.New(4, 2, 6)
	local actual = vector1 == vector2
	local expected = true

	print("\nTest_Equals():\n", assert(actual == expected, "Actual: " .. tostring(actual) .. " - Expected: " .. tostring(expected)))
end

function Test_ToString()
	local vector = vectorAPI.New(4, 2, 6)
	local actual = tostring(vector)
	local expected = "4,2,6"

	print("\nTest_ToString():\n", assert(actual == expected, "Actual: " .. actual .. " - Expected: " .. expected))
end


function Test_AreOrthogonal()
    local vector1 = vectorAPI.New(1, 0, 0)
    local vector2 = vectorAPI.New(0, 1, 0)
    
    local areOrthogonal = vector1:IsOrthogonalTo(vector2)
    
    print("Test_AreOrthogonal(): ", assert(areOrthogonal))
end

function Test_AreNotOrthogonal()
    local vector1 = vectorAPI.New(1, 0, 0)
    local vector2 = vectorAPI.New(1, 1, 0)
    
    local areOrthogonal = vector1:IsOrthogonalTo(vector2)
    
    print("Test_AreNotOrthogonal(): ", assert(not areOrthogonal))
end

function Test_AreOrthonormal()
    local vector1 = vectorAPI.New(1, 0, 0)
    local vector2 = vectorAPI.New(0, 1, 0)
    
    local areOrthonormal = vector1:AreOrthonormalTo(vector2)
    
    print("Test_AreOrthonormal(): ", assert(areOrthonormal))
end

function Test_AreNotOrthonormal()
    local vector1 = vectorAPI.New(1, 0, 0)
    local vector2 = vectorAPI.New(1, 1, 0)
    
    local areOrthonormal = vector1:AreOrthonormalTo(vector2)
    
    print("Test_AreNotOrthonormal(): ", assert(not areOrthonormal))
end



Test_Add()
Test_Subtract()
Test_Multiply()
Test_Divide()
Test_Negate()
Test_Dot()
Test_Cross()
Test_Length()
Test_Normalize()
Test_Project()
Test_Round()
Test_Equals()
Test_ToString()
Test_AreOrthogonal()
Test_AreNotOrthogonal()
Test_AreOrthonormal()
Test_AreNotOrthonormal()