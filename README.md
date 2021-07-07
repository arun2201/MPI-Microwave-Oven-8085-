# MPI-Microwave-Oven-8085-
**Built and simulated a Microwave Oven from scratch using proteus and ALP**


Description:
A Simple Microwave Oven without a grill.
• User can cook at 5 different Power levels: 100%, 80%, 60%, 40 % 20%
• Ever press of the Power Button decrements the power level by 20 %
• 1 Press - 100%; 2 Presses – 80% ; 3 Presses – 60%; 4 Presses – 40 %; 5 Presses – 20%
• 6 Presses – Brings the power level back to 100 %
• The Default power level is 100%
• Power Level is varied by controlling the amount of time for which the microwave is turned on.
• Time of cooking is broken up into 10-sec slots, if power is 60% then for 6 secs the microwave is on
and rest of the 4 secs the microwave is off.
• Time is set as multiples of 10 Mins, 1Min, 10 Secs. For e.g., if the cooking time is 12 Minutes and 40
secs- the 10 Minutes button has to be pressed once, 1 Minute Button has to be pressed Twice, and
10 seconds button has to be pressed four times.
• Once Time has been set Power cannot be modified.
• When the user is setting power level or Time, the value being pressed should be displayed, and
when the user presses the Start button, the cooking process begins and the time left for cooking to
complete is displayed.
• Once the cooking begins, the door gets locked and should open only when the cooking process is
terminated.
• User can terminate cooking anytime by pressing the STOP button.
• When the Stop button is pressed once cooking is aborted, timer is stopped, not cleared; cooking can
be resumed by pressing Start.
• When the stop is pressed twice, cooking is aborted, and the timer is also cleared.
• When cooking time elapses, a buzzer is sounded; pressing the Stop Button stops the buzzer.
• A Quick Start mode is available where timer or power need not be set, just Start button needs to be
pressed, the default power value is taken and time is set as 30 secs, for every press of the start
button time is incremented by 30 seconds.

ASSUMPTIONS:
● Only one button is being pressed at a time
● The door will only open once the cooking ends and stop is pressed or if stop is
pressed twice.
● Initial power level in % is displayed in the format 0PPP (e.g. 0080 for 80%)
● At all other times, the timer is displayed in place of the power level.
● Time is displayed in the format MM:SS where the minimum time is 00:00 and
maximum is 99:59 (realistically 99:50)
● The timer, if increased beyond 99:50 using the 10s button, will return to 00:00
● There exists a mechanism that can utilize the digital signal (in the specified
power level form) from our system to activate the Magnetron
● Even in quick start mode the user may set the power, though not necessarily

JUSTIFICATIONS:
● To ensure that the microwave cannot be powered while the door is open, the
power to the system is delivered only if the door is closed.
● The outputs for the lock and the buzzer are put through a tri-state buffer to meet
their current requirements without affecting the ports of 8255.
● Hardware Debounce Circuit has been added to filter out switch chatter.
● We have used a byte of flags in memory(Active, Paused, Power, Buzzer,
TimeSet) along with a main loop and a set of 7 branching isr’s. This was done
to make our design work as a state system.
