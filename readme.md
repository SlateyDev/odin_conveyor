# Conveyor: ODIN + RayLib test project

This project is a personal challenge to make something in ODIN. The
challenge needed a further goal and that was something to make so I
decided to make a conveyor system. To help with the creation of this
conveyor system I decided to work with RayLib.

Any other features are just because I wanted to learn to use them at
the same time while I was learning ODIN and decided to use this
project as part of that learning. eg. MicroUI, memory tracking
allocator, vscode launch/tasks configuration.

This project has been setup to hopefully "just work" when loaded
into a vscode environment on a system that has odin installed. The
configuration for the launch/tasks vscode configuration files were
found in another repository and modified slightly to my own personal
tastes.

### TODO:

- [x] Open window
- [x] Render rectangles
- [x] Render sprite
- [x] Animate sprite
- [x] Placement of conveyors on a grid
- [x] MicroUI
- [ ] Place item on conveyor
- [ ] Have item move with conveyor
- [ ] Have item move to linked conveyor
- [ ] Make sure items don't overlap other items already on conveyor
- [ ] Move code into separate files
- [ ] Cleanup code

### Actions:

I couldn't quite think of how I wanted to make feeders/eaters and
support other possible actions that could happen on the conveyor
so I created a direction called ACTION that would be like a
nothing direction, meaning an item was coming from something and
going to the to direction or coming from a from direction and
going to something. I then allowed a conveyor section to define
an action which could be a feeder/eater or anything else. This
could also allow for an action that would change an object in
some way and feed in and back out. Still looking how I can use
this, or should I just make conveyor sections that are specific.

Another possibility is that a conveyor piece is defined as an
entry point and an exit point (or multiple entry/exit points) with
an action, and that action could just be do nothing. Then define
an image for each of these conveyor sections. I would then need to
define corner pieces possibly and define how things link.