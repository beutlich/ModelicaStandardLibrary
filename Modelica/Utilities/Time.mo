within Modelica.Utilities;
package Time "Functions to work with date and time"
  extends Modelica.Icons.FunctionsPackage;

  impure function getTime "Retrieve the current time (in the local time zone)"
    extends Modelica.Icons.Function;
    output Types.TimeType now "Current time";
  algorithm
    (now.ms, now.sec, now.min, now.hour, now.day, now.mon, now.year) := Internal.Time.getTime();
    annotation (Documentation(info="<html>
<h4>Syntax</h4>
<blockquote><pre>
now = Time.<strong>getTime</strong>();
</pre></blockquote>
<h4>Description</h4>
<p>
Returns the local time at the time instant this function was called.
The returned value is of type <a href=\"modelica://Modelica.Utilities.Types.TimeType\">TimeType</a>.
</p>

<h4>Example</h4>
<blockquote><pre>
now = getTime()   // = Modelica.Utilities.Types.TimeType(281, 30, 13, 10, 15, 2, 2015)
                  // Feb. 15, 2015 at 10:13 after 30.281 s
</pre></blockquote>
<h4>Note</h4>
<p>This function is impure!</p>
</html>"));
  end getTime;
    annotation (
Documentation(info="<html>
<p>
This package contains functions to work with date and time.
</p>
</html>"));
end Time;
