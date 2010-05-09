-- PUMICE Copyright (C) 2009 Lars Rosengreen (-*-coding:iso-safe-unix-*-)
-- released as free software under the terms of MIT open source license


require "vector"
require "matrix"

isolv = {}


-- solve Au = b using the conjugate gradient method
-- 
-- A    - a square nxn matrix
-- b    - a vector of size n
-- eps  - stop iterating if norm of the residuals is smaller than this; 0 by 
--        default
-- step - stop after this many iterations; n by default
-- u0   - what to use as a best guess of the solutions; zero vector of n 
--        elements by default
--
-- returns u, the vector of the found solutions
function cg(A, b, eps, steps, u0)
   -- set defaults
   local ers = ers or 0
   local steps = steps or A.rows
   local u = u0 or vector.new(b.size)

   local r = b - A * u
   local p = r
   k = 1
   repeat
      local w = A * p
      local lambda = vector.dot(p, r) / vector.dot(p, w)
      u = u + lambda * p
      local rnew = r - lambda * w
      local alpha = vector.dot(rnew, rnew) / vector.dot(r, r)
      r = rnew
      p = r + alpha * p
      k = k + 1
   until k > steps or vector.norm(rnew) <= eps
   return u, steps, vector.norm(rnew)
end


return isolv