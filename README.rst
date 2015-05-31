-----------------------
ModifyField package
-----------------------

This package provides methods for the function modifyField!, which is intended
to modify a field of an immutable object that sits inside of a container.  To illustrate
the issue, consider the following immutable structure::

   immutable Immut
       intfld1::Int
       isadded::Bool
   end

Suppose ``a`` is an array of type ``Immut`` and we wish to perform the following
loop::

   t = 0
   for k = 1 : n
       t += a[k].intfld1
       a[k].isadded = true
   end

Unfortunately, the above code snippet is illegal because it modifies a field of an
immutable object.  Instead, we could obtain the same effect legally via::

   t = 0
   for k = 1 : n
       t += a[k].intfld1
       a[k] = Immut(a[k].intfld, true)
   end

The problem with this code is that it becomes unwieldy for a structure with
many fields.  In this case, it would be hard to read and also a possible source of bugs.

----------------------
Invoking modifyField!
----------------------

The purpose of this package is to provide a function ``modifyField!`` for
use in the above context as follows::

   t = 0
   for k = 1 : n
       t += a[k].intfld1
       modifyField!(a, k, Val{:isadded}, true)
   end

The arguments to ``modifyField!`` are as follows.  The first argument is the
name of the container.  The second is the subscript.  In the case of an array
or other container with *k* subscripts, arguments 2 through *k*+1 are the subscripts.

The third argument specifies the field to be modified.  A natural way to specify
the field might be ``:isadded``, the Julia syntax for specifying a symbol.  However,
the package uses the more elaborate specification ``Val{:isadded}`` because this
allows the compiler to choose which ``modifyField!`` variant should be invoked at
compile time.  This is because ``Val{:isadded}`` is of a type (namely,
``Type{Val{:isadded}}``) uniquely determined by
the symbol ``:isadded``, and Julia dispatches different methods based
on argument type.   (Refer to the Julia manual for information about ``Type`` and
``Val``.)   In contrast, if the third argument were simply ``:isadded`` 
then it would be up to ``modifyField!`` at run-time to dispatch to the correct
modifier because any object like ``:isadded`` or ``:intfld`` is of type ``Symbol.``

Finally, the fourth argument is the new value that should be assigned to the particular
entry of the container indexed by the given subscript(s).

Of course, you could easily write ``modifyField!`` for yourself.  You
would probably write something like this::

   #  helper routine to generate the modified Immut from a given Immut called x
   copyandmodify(x::Immut, Type{Val{:isadded}}, newval) = Immut(x.intfld, newval)

   function modifyField!(a::Array{Immut,1}, k::Int, Type{Val{:isadded}}, newval)
      a[k] = copyandmodify(a[k], Val{:isadded}, newval)
      nothing
   end

This package writes these functions for you: it generates functions
of this format called ``copyandmodify`` and ``modifyField`` for any composite type that
you provide.

-----------------------------------------------
Creating modifyField! functions for your type
-----------------------------------------------

The usage of the package is as follows.  Precede your code with the declaration
``using Modifyfield``.  Next, declare any immutable types for which you want
to have ``modifyField!`` routines.  For example, suppose your type is
called ``Immut`` as in the above snippet. Then, at the top level of your source code
(i.e., not inside any function), include the following statements::

    makecopyandmodify(Immut)
    makemodifyfield(Immut, Array{Immut,1}, 1)

These statements must come after the ``using`` declaration and also after
the definition of ``Immut``.  

The first statement creates all the ``copyandmodify`` functions for the type.
The second statement creates the ``modifyField!`` functions for the type for
a particular container (in this case, a 1-dimensional array).  
Include multiple ``makemodifyfield`` calls if you plan to use ``Immut`` in other
types of containers (2D arrays, dictionaries, etc).  The other two arguments
to ``makemodifyfield`` are the base type (first argument) and number of subscripts
needed by the container (third argument).  In principle, these other two arguments
are redundant, i.e., it should be possible for ``makemodifyfield`` to deduce the
base type and number of subscripts from the container type, but I couldn't figure
out how to extract this information in a general way when I wrote the package.

These functions ``makecopyandmodify`` and ``makemodifyfield`` are
executed when the module loads; the functions they create (``copyandmodify`` and
``modifyField``) are then available
for use by other routines in your code.




   
