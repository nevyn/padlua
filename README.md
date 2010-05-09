padlua
============

Padlua is a simple interactive Lua shell for the iPad. It comes with a few libraries (pumice for vector+matrix math e g) and a custom keyboard attachment.

![Screenshot](http://dl.dropbox.com/u/6775/padlua1.PNG "Screenshot")

How do I use it?
------------------------
The upper half is output, lower half is input. Just type a lua expression in the lower half (including function definitions and whatever), press "Run", and it'll evaluate in the upper half. Press the green arrows for command history. The result(s) of the previous command are saved to globals called ret[n] and can be used in subsequent commands.

If you press the clover button, you get a settings window into which you can type a space-separated list of function names. Functions with these names in the global scope will be serialized to disk when you exit. Command history, input and output window contents are also saved on exit. Other variables and state are *not* saved; I'm not sure how to proceed here, how much one should save.

Author
------------------
[Joachim Bengtsson](mailto:joachimb@gmail.com)

License
------------------
Public domain.