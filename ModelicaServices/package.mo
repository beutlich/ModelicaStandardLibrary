within ;
package ModelicaServices "ModelicaServices (Unofficial Dymola implementation required during development) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  extends Modelica.Icons.Package;
  constant String target="Dymola"
    "Target of this ModelicaServices implementation";

  package UsersGuide "User's Guide"
    extends Modelica.Icons.Information;
    class ReleaseNotes "Release notes"
      extends Modelica.Icons.ReleaseNotes;
      annotation (Documentation(info="<html>
<h4>Version 4.0.0, 2020-06-04</h4>

<ul>
<li> New animation visualizer
     <a href=\"modelica://ModelicaServices.Animation.Vector\">Vector</a>
     for 3D animation of a vector quantity (force, torque etc), see <a href=\"https://github.com/modelica/ModelicaStandardLibrary/issues/1891\">#1891</a>.
     </li>
</ul>

<h4>Version 3.2.3, 2019-01-23</h4>

<ul>
<li> New function
     <a href=\"modelica://ModelicaServices.System.exit\">exit</a>
     to terminate the Modelica environment, see <a href=\"https://github.com/modelica/ModelicaStandardLibrary/issues/2211\">#2211</a>.
     </li>
</ul>

<h4>Version 3.2.1, 2012-12-05</h4>

<ul>
<li> Version numbering adapted to the corresponding version number of
     package Modelica (= Modelica Standard Library).</li>
<li> New function
     <a href=\"modelica://ModelicaServices.ExternalReferences.loadResource\">loadResource</a>
     to determine the absolute, local file name from an URI path name.
     </li>
<li> New String type with tool dependent choices
     <a href=\"modelica://ModelicaServices.Types.SolverMethod\">SolverMethod</a>
     to define the integration method to solve differential equations in a
     clocked discretized continuous-time partition.
     </li>
<li> New package
     <a href=\"modelica://ModelicaServices.Machine\">Machine</a>
     to define the processor dependent constants as used in
     <a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.
     </li>
</ul>

<h4>Version 1.1, 2010-07-30</h4>

<ul>
<li> New model <a href=\"modelica://ModelicaServices.Animation.Surface\">Surface</a>
     to describe movable, parameterized surfaces.</li>
<li> New string constant ModelicaServices.target to define the
     target of the corresponding ModelicaServices implementation</li>
<li> Package icons adapted to the icons of package Modelica, version 3.2.</li>
<li> ModelicaServices library on the Modelica subversion server provided in three versions:
     <ol>
     <li> <strong>Default/ModelicaServices</strong><br>
          (for tools that do not support 3-dim. visualization).</li>

     <li> <strong>Dymola/ModelicaServices</strong><br>
          (a Dymola-specific implementation).</li>

     <li> <strong>DymolaAndDLRVisualization/ModelicaServices</strong><br>
          (an implementation that uses the DLR Visualization library
           in combination with Dymola).</li>
     </ol>
     </li>
</ul>

<h4>Version 1.0, 2009-06-21</h4>

<p>
First version of the ModelicaServices library.
</p>
</html>"));
    end ReleaseNotes;

    class Contact "Contact"
      extends Modelica.Icons.Contact;
      annotation (Documentation(info="<html>
<h5>Main Author</h5>

<table border=\"0\" cellspacing=\"0\" cellpadding=\"2\">
<tr>
<td>
<a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
    Deutsches Zentrum f&uuml;r Luft und Raumfahrt e.V. (DLR)<br>
    Robotik und Mechatronik Zentrum (RMC)<br>
    Institut f&uuml;r Systemdynamik und Regelungstechnik (SR)<br>
    Postfach 1116<br>
    D-82230 Wessling<br>
    Germany<br>
    email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></td>
</tr>
</table>

<p><strong>Acknowledgements:</strong></p>

<p>
The design of the Animation.Shape component is from Hilding Elmqvist, previously at Dassault Syst&egrave;mes AB.
</p>
</html>"));
    end Contact;
    annotation (DocumentationClass=true);
  end UsersGuide;

  package Animation "Models and functions for 3-dim. animation"
    extends Modelica.Icons.Package;
    model Shape
      "Different visual shapes with variable size; all data have to be set as modifiers (see info layer)"
      extends Modelica.Utilities.Internal.PartialModelicaServices.Animation.PartialShape;

      import T = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices;
      import SI = Modelica.Units.SI;
      import Modelica.Mechanics.MultiBody.Frames;
      import Modelica.Mechanics.MultiBody.Types;

    protected
      parameter Boolean isURI=Modelica.Utilities.Strings.find(shapeType, "modelica://", caseSensitive=false)==1 or
        Modelica.Utilities.Strings.find(shapeType, "file://", caseSensitive=false)==1 or
        Modelica.Utilities.Strings.find(shapeType, "%")==1 annotation(Evaluate=true);
      Real abs_n_x(final unit="1") annotation (HideResult=true);
      Real n_z_aux[3](each final unit="1") annotation (HideResult=true);
      Real e_x[3](each final unit="1", start={1,0,0})
        "Unit vector in lengthDirection, resolved in object frame" annotation (HideResult=true);
      Real e_y[3](each final unit="1", start={0,1,0})
        "Unit vector orthogonal to lengthDirection in the plane of lengthDirection and widthDirection, resolved in object frame"
        annotation (HideResult=true);
      output Real Form(unit=if isURI then ":"+shapeType else "") annotation (HideResult=false);
    public
      output Real rxvisobj[3](each final unit="1")
        "x-axis unit vector of shape, resolved in world frame" annotation (HideResult=false);
      output Real ryvisobj[3](each final unit="1")
        "y-axis unit vector of shape, resolved in world frame" annotation (HideResult=false);
      output SI.Position rvisobj[3] "Position vector from world frame to shape frame, resolved in world frame"
        annotation (HideResult=false);
    protected
      output SI.Length size[3] "{length,width,height} of shape" annotation (HideResult=false);
      output Real Material annotation (HideResult=false);
      output Real Extra annotation (HideResult=false);
    equation
      abs_n_x = Modelica.Math.Vectors.length(lengthDirection);
      e_x     = noEvent(if abs_n_x < 1.e-10 then {1,0,0} else lengthDirection/abs_n_x);
      n_z_aux = cross(e_x, widthDirection);
      e_y     = noEvent(cross(Modelica.Math.Vectors.normalize(
                       cross(e_x, if n_z_aux*n_z_aux > 1.0e-6 then widthDirection else
                                 (if abs(e_x[1]) > 1.0e-6 then {0,1,0} else {1,0,0}))), e_x));

      /* Outputs to file. */
      Form = (987000 + PackShape(if isURI then "13" else shapeType))*1E20;
      /*
      rxry = Frames.TransformationMatrices.to_exy(
        Frames.TransformationMatrices.absoluteRotation(R.T,
        Frames.TransformationMatrices.from_nxy(lengthDirection, widthDirection)));
      rxvisobj = rxry[:, 1];
      ryvisobj = rxry[:, 2];
    */
      rxvisobj = transpose(R.T)*e_x;
      ryvisobj = transpose(R.T)*e_y;
      rvisobj = r + T.resolve1(R.T, r_shape);
      size = {length,width,height};
      Material = PackMaterial(color[1]/255.0, color[2]/255.0, color[3]/255.0,
        specularCoefficient);
      Extra = extra;
    annotation (
      Icon(coordinateSystem(
        preserveAspectRatio=true,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics),
      Documentation(info="<html>
<p>The interface of this model is documented at <a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape</a>. </p>
<p>This implementation is targeted for Dymola. Here, the following data is stored on the result file (using Dymola specific functions &quot;PackShape&quot; and &quot;PackMaterial&quot; to pack data on a Real number): </p>
<blockquote><pre>
Real Form         // shapeType coded on Real
Real rxvisobj[3]  // x-axis unit vector of shape, resolved in world frame
Real ryvisobj[3]  // y-axis unit vector of shape, resolved in world frame
Real rvisobj [3]  // Position vector from world frame to shape frame, resolved in world frame
Real size    [3]  // {length,width,height} of shape
Real Material     // color and specularCoefficient packed on Real
Real Extra        // &quot;extra&quot; variable of shape
</pre></blockquote>
<p>It is then assumed that the program reading the result file recognizes that a 3-dim. visualizer object is defined (via variable &quot;Form&quot; and the possible values for Forms) and then visualizes the shape according to the follow-up data. </p>
<p>Note that shapeType now supports dxf-files in libraries - either in the form &quot;&percnt;PackageName&percnt;/file.dxf&quot; or from next Dymola version also a URI &quot;modelica://PackageName/file.dxf&quot;.</p>
</html>"));
    end Shape;

    model Surface
      "Animation of a moveable, parameterized surface; the surface characteristic is provided by a function"
      import Modelica.Mechanics.MultiBody.Frames;
      import Modelica.Mechanics.MultiBody.Types;

      input Frames.Orientation R=Frames.nullRotation()
        "Orientation object to rotate the world frame into the surface frame"
        annotation(Dialog(group="Surface frame"));
      input Modelica.Units.SI.Position r_0[3]={0,0,0}
        "Position vector from origin of world frame to origin of surface frame, resolved in world frame"
        annotation(Dialog(group="Surface frame"));

      parameter Integer nu=2 "Number of points in u-Dimension" annotation(Dialog(group="Surface properties"));
      parameter Integer nv=2 "Number of points in v-Dimension" annotation(Dialog(group="Surface properties"));
      replaceable function surfaceCharacteristic =
        Modelica.Mechanics.MultiBody.Interfaces.partialSurfaceCharacteristic
        "Function defining the surface characteristic"
        annotation(choicesAllMatching=true,Dialog(group="Surface properties"));

      parameter Boolean wireframe=false
        "= true: 3D model will be displayed without faces"
        annotation (Dialog(group="Material properties"));
      parameter Boolean multiColoredSurface=false
        "= true: Color is defined for each surface point"
        annotation(Dialog(group="Material properties"));
      input Real color[3]={255,0,0} "Color of surface" annotation(Dialog(__Dymola_colorSelector=true,group="Material properties"));
      input Types.SpecularCoefficient specularCoefficient = 0.7
        "Reflection of ambient light (= 0: light is completely absorbed)" annotation(Dialog(group="Material properties"));
      input Real transparency=0
        "Transparency of shape: 0 (= opaque) ... 1 (= fully transparent)"
        annotation(Dialog(group="Material properties"));
    protected
      parameter Boolean smoothSurface=true "= true: 3D model will be smooth"
        annotation (Dialog(group="Material properties"));
      Real ObjectType;
      output Real Form = 987000 + ObjectType  annotation(HideResult=false);
      output Real rxvisobj[3](each final unit="1")
        "x-axis unit vector of surface, resolved in world frame"
        annotation (HideResult=false);
      output Real ryvisobj[3](each final unit="1")
        "y-axis unit vector of surface, resolved in world frame"
        annotation (HideResult=false);
      output Modelica.Units.SI.Position rvisobj[ 3]
        "Position vector from world frame to surface frame, resolved in world frame"
        annotation (HideResult=false);
      output Real material annotation (HideResult=false);
      output Real extra annotation (HideResult=false);
      output Real alpha annotation(HideResult=false);
      output Real NumberOfU annotation (HideResult=false);
      output Real NumberOfV annotation (HideResult=false);
      Real x[nu, nv] annotation (HideResult=false);
      Real y[nu, nv] annotation (HideResult=false);
      Real z[nu, nv] annotation (HideResult=false);
      Real C[if multiColoredSurface then nu else 0, if multiColoredSurface then nv else 0, 3] annotation (HideResult=false);
    equation
      (x, y, z, C) = surfaceCharacteristic(nu,nv,multiColoredSurface);

      ObjectType = if multiColoredSurface then 67 else 77;
      NumberOfU = nu;
      NumberOfV = nv;
      material = PackMaterial(
        color[1]/255.0,
        color[2]/255.0,
        color[3]/255.0,
        specularCoefficient);
      extra = (if wireframe then 4.0 else 0.0)+(if smoothSurface then 1 else 0);
      alpha = 1 - transparency;
      rvisobj = r_0;
      rxvisobj = R.T[1,1:3];
      ryvisobj = R.T[2,1:3];
    annotation (Documentation(info="<html>
<p>
The interface of this model is documented at
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface</a>.
</p>

<p>
This implementation is targeted for Dymola.
</p>

</html>"));
    end Surface;

    model Vector "Animation of a moveable vector-quantity (the length is not fixed in meters)"
      extends Modelica.Utilities.Internal.PartialModelicaServices.Animation.PartialVector;
      import Modelica.Mechanics.MultiBody.Types.VectorQuantity;

      VisualVector vis(
        pushing=headAtOrigin,
        S=R.T,
        Size=coordinates,
        r=r,
        category=if quantity==VectorQuantity.Force then "force" elseif quantity==VectorQuantity.Torque then "torque" elseif quantity==VectorQuantity.Velocity then "velocity" elseif quantity==VectorQuantity.Acceleration then "acceleration" elseif quantity==VectorQuantity.AngularVelocity then "angular velocity" elseif quantity==VectorQuantity.AngularAcceleration then "angular acceleration" else "unknown");
  annotation (Documentation(info="<html>
<p>
The interface of this model is documented at
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Vector\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Vector</a>.<br>
The interface of this model is defined at
<a href=\"modelica://Modelica.Utilities.Internal.PartialModelicaServices.Animation.PartialVector\">Modelica.Utilities.Internal.PartialModelicaServices.Animation.PartialVector</a>.
</p>

</html>"));
    end Vector;
  end Animation;

  package ExternalReferences "Library of functions to access external resources"
    extends Modelica.Icons.Package;
    function loadResource "Return the absolute path name of a URI or local file name"
      extends Modelica.Icons.Function;
      input String uri;
      output String fileReference;
      external "builtin" fileReference=Dymola_ResolveURI(uri);
  annotation (Documentation(info="<html>
<h4>Syntax</h4>
<blockquote><pre>
fileReference = <strong>loadResource</strong>(uri);
</pre></blockquote>
<h4>Description</h4>
<p>
The function call \"<strong>loadResource</strong>(uri)\" returns the
<strong>absolute path name</strong> of the file that is either defined by an URI or by a local
(e.g. relative) path name. With the returned file name it is possible to
access the file with function calls of the C standard library.
If the data or file is stored in a data-base,
this might require copying the resource to a temporary folder and referencing that.
</p>

<p>
The implementation of this function is tool specific, and this implementation is for Dymola.
However, at least Modelica URIs
(see \"chapter 13.2.3 External Resources\" of the Modelica Specification),
as well as absolute and relative local file path names are supported.
</p>

<h4>Example</h4>
<blockquote><pre>
  file1 = loadResource(\"modelica://Modelica/Resources/Data/Utilities/Examples_readRealParameters.txt\")
          // file1 is the absolute path name of the file
  file2 = loadResource(\"C:\\data\\readParameters.txt\")
          file2 = \"C:/data/readParameters.txt\"
</pre></blockquote>
</html>"));
    end loadResource;
  end ExternalReferences;

  package Machine "Machine dependent constants"
    extends Modelica.Icons.Package;
    final constant Real eps=1e-15 "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small=1e-60
      "Smallest number such that small and -small are representable on the machine";
    final constant Real inf=1e60
      "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf=2147483647
      "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
    annotation (Documentation(info="<html>
<p>
Package in which processor specific constants are defined that are needed
by numerical algorithms. Typically these constants are not directly used,
but indirectly via the alias definition in
<a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.
</p>
</html>"));
  end Machine;

  package System "System dependent functions"
    extends Modelica.Icons.Package;
    impure function exit "Terminate execution of Modelica environment"
      extends Modelica.Utilities.Internal.PartialModelicaServices.System.exitBase;
      external "C" exit(status) annotation(Include="#include <stdlib.h>", Library="ModelicaExternalC");
      annotation(Documentation(info="<html>
<p>
Tool-specific implementation of <a href=\"modelica://Modelica.Utilities.System.exit\">Modelica.Utilities.System.exit</a>.
</p>
</html>"));
    end exit;
  end System;

  package Types "Library of types with vendor specific choices"
    extends Modelica.Icons.Package;
    type SolverMethod = String
      "String defining the integration method to solve differential equations in a clocked discretized continuous-time partition"
      annotation (choices(
        choice="External" "Solver specified externally",
        choice="ExplicitEuler" "Explicit Euler method (order 1)",
        choice="ExplicitMidPoint2" "Explicit mid point rule (order 2)",
        choice="ExplicitRungeKutta4" "Explicit Runge-Kutta method (order 4)",
        choice="ImplicitEuler" "Implicit Euler method (order 1)",
        choice="ImplicitTrapezoid" "Implicit trapezoid rule (order 2)"),
        Documentation(info="<html>
<p>
Type <strong>SolverMethod</strong> is a String type with menu choices to select the
integration method to solve differential equations in a clocked discretized
continuous-time partition. The choices are tool dependent.
For details, see chapter 16.8.2 \"Solver Method\" in the Modelica Language
Specification (version &ge; 3.3).
</p>
</html>"));
  end Types;

  annotation (
    preferredView="info",
    version="4.0.0",
    versionDate="2020-06-04",
    dateModified = "2020-06-04 11:00:00Z",
    revisionId="$Format:%h %ci$",
    uses(Modelica(version="4.0.0")),
    conversion(
      noneFromVersion="1.0",
      noneFromVersion="1.1",
      noneFromVersion="1.2",
      noneFromVersion="3.2.1",
      noneFromVersion="3.2.2"),
    Documentation(info="<html>
<p>
This package contains a set of functions and models to be used in the
Modelica Standard Library that requires a tool specific implementation.
These are:
</p>

<ul>
<li> <a href=\"modelica://ModelicaServices.Animation.Shape\">Animation.Shape</a>
     provides a 3-dim. visualization of elementary
     mechanical objects. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Animation.Surface\">Animation.Surface</a>
     provides a 3-dim. visualization of
     moveable parameterized surface. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Animation.Vector\">Animation.Vector</a>
     provides a 3-dim. visualization of vector quantities. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Arrow\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Arrow</a>, <a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.DoubleArrow\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.DoubleArrow</a> and <a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.FixedArrow\">Modelica.Mechanics.MultiBody.Visualizers.FixedArrow</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.ExternalReferences.loadResource\">ExternalReferences.loadResource</a>
     provides a function to return the absolute path name of an URI or a local file name. It is used in
<a href=\"modelica://Modelica.Utilities.Files.loadResource\">Modelica.Utilities.Files.loadResource</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Machine\">Machine</a>
     provides a package of machine constants. It is used in
<a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.</li>

<li> <a href=\"modelica://ModelicaServices.System.exit\">System.exit</a> provides a function to terminate the execution of the Modelica environment. It is used in <a href=\"modelica://Modelica.Utilities.System.exit\">Modelica.Utilities.System.exit</a> via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Types.SolverMethod\">Types.SolverMethod</a>
     provides a string defining the integration method to solve differential equations in
     a clocked discretized continuous-time partition
     (see <a href=\"https://specification.modelica.org/v3.4/Ch16.html#solver-methods\">Section 16.8.2 (Solver Methods) of the Modelica 3.4 specification</a>).</li>
</ul>

<p>
This is the default implementation, if no tool-specific implementation is available.
This ModelicaServices package provides only \"dummy\" models that do nothing.
</p>

<p>
<strong>Licensed by the Modelica Association under the 3-Clause BSD License</strong><br>
Copyright &copy; 2009-2020, Modelica Association and contributors
</p>

<p>
<em>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the 3-Clause BSD license. For license conditions (including the disclaimer of warranty) visit <a href=\"https://modelica.org/licenses/modelica-3-clause-bsd\">https://modelica.org/licenses/modelica-3-clause-bsd</a>.</em>
</p>

</html>"));
end ModelicaServices;
