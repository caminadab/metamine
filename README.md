# Metamine
A completely declarative programming language. Imperative programming is a thing of the past!

Instead of building code the traditional way - using for loops, a linear control flow, and variables - metamine enables you to write code using equations instead of statements. These equations are immutable and timeless: an equation such as `x = y + 1` can be placed anywhere in the source code and will always hold. An application is simply how you define the term `out`.

A bunch of predefined terms (not variables) are defined, such as `now` (which refers to the current time), `mouse.x` (which refers to the x-position of the mouse), `screen.width` (the screen width), etcetera. Refer to the catalogue to view all built-in variables. All these terms are always live; simply writing `out = runtime` would result in a timer application.

# Data types
Metamine uses a type system but does not support type annotations. The following basic types are supported: `int`, `letter`, `number`, `bit`. Compound types are `list`, `set`, `tuple`. Compound types allow type arguments so that you can have `list(letter)` as text or `list(list(number))` for a matrix.

# Examples

## Hello world
A simple hello world example would be:

    out = "hello world"
 
This would result in the predictable output:
 
     hello world
     
## Timer
To create a simple timer you can use:
 
    out = 10 - runtime
 
Which would result in an application that counts back from 10.
 
## Paint
To create visual output, we can use the function `draw`. This takes a list of objects as arguments and outputs a canvas with those objects.

    out = draw objects
    objects = [ circle(mouse.x, mouse.y, 10) ]
    
 This results in a canvas with a circle that follows the mouse: `[` and `]` denote a list, `circle` is a function that takes the x- and y-position and the radius of the circle.
 
# Variables
Metamine supports variables, but in a declarative way. Using the assign operator `:=` it is possible to assign values at certain moments. Let's see at an example program that prints how many times you have clicked:

    numclicks := 0
    if mouse.click.begin then
        numclicks := numclicks + 1
    end
    out = numclicks
    
Note that the equations can still be in any order: the compiler aggregates all assignments for a variable and creates an *update* function for this variable.
The first equation, `numclicks := 0`, is in the *main scope*: not inside any if-statement. This means that this variable is updated at the start at the program with the value `0`.

The second equation, `numclicks := numclicks + 1`, is inside the if-statement. This means that anytime the if-statement is `true`, the assignment will execute and increase `numclicks` by `1`. Note that you cannot write `numclicks = numclicks + 1` because this is not an assignment and should generate an error.

# How to use
Clone the repository and execute `make run` to start a local metamine server. In the browser, open http://localhost:1237/ to edit and run metamine code.
