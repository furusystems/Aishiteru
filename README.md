Aishiteru
=========

OpenFL gamedev tools.

These are tools originally written in AIR/AS3 built expressly for our OpenFL game engine, which renders exclusively using graphics.drawTiles and graphics.drawTriangles. The goal is to switch this renderer out for an OpenGLView based one.

They include 
  Compilation of textures
  Building optimized animation data from sprite sheets
  Creation of linearly interpolated point-to-point motion paths
  Creation of FK based bone animations for larger characters
  
The goal is to port the tools to Haxe3, optimize and improve on the workflow, unification of the whole bunch into a single application, and supporting project files and automated project structure management.

Additionally, libraries will be formalized to allow this renderer to be used for other game engines.
