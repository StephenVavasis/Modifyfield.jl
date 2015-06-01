-----------------------
Modifyfield package
-----------------------

This Julia package provides methods for the function ``modifyField!``, which is intended
to modify a field of an immutable object that sits inside of a container.  To illustrate
the issue, consider the following immutable structure::

   immutable Immut
       intfld::Int
       isadded::Bool
   end

Suppose ``a`` is an array of type ``Immut`` and we wish to perform the following
loop::

   t = 0
   for k = 1 : n
       t += a[k].intfld
       a[k].isadded = true
   end

Unfortunately, the above code snippet is illegal because it modifies a field of an
immutable object.  Instead, we could obtain the same effect legally via::

   t = 0
   for k = 1 : n
       t += a[k].intfld
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
       t += a[k].intfld
       modifyField!(a, k, Val{:isadded}, true)
   end

The arguments to ``modifyField!`` are as follows.  The first argument is the
name of the container.  The second is the subscript.  In the case of an array
or other container with *k* subscripts, arguments 2 through (*k* + 1) are the subscripts.

The third argument specifies the field to be modified.  A natural way to specify
this argument might be ``:isadded``, the Julia syntax for specifying a symbol.  Instead,
the package uses the more elaborate specification ``Val{:isadded}`` because this
allows the compiler to choose at compile time
which ``modifyField!`` variant should be invoked.  This is because the type of ``Val{:isadded}`` (namely,
``Type{Val{:isadded}}``) is uniquely determined by
the symbol ``:isadded``, and Julia dispatches different methods based
on argument type.   (Refer to the Julia manual for information about ``Type`` and
``Val``.)   In contrast, if the third argument were simply ``:isadded`` 
then ``modifyField!`` would need to compute the correct dispatch at
run-time because objects like ``:isadded`` and ``:intfld`` are the
same type (``Symbol``).

Finally, the fourth argument is the new value that should be assigned to the particular
field of the particular entry of the container indexed by the given subscript(s).

The instance of ``modifyField!`` described in the example
would be straightforward to write; here is how it would look::

   #  helper routine to compute the modified Immut from a given Immut x
   copyandmodify(x::Immut, ::Type{Val{:isadded}}, newval) = Immut(x.intfld, newval)

   function modifyField!(a::Array{Immut,1}, k::Int, ::Type{Val{:isadded}}, newval)
      a[k] = copyandmodify(a[k], Val{:isadded}, newval)
      nothing
   end

This package writes these functions automatically: it generates functions
of this format called ``copyandmodify`` and ``modifyField`` for any composite type that
is provided.

----------------------------------------------------
Creating modifyField! functions for a composite type
----------------------------------------------------

The usage of the package is as follows.  Include the declaration
``using Modifyfield``.  Next, declare any immutable types for which
``modifyField!`` routines are desired.  For example, suppose that the 
``Immut`` is in the code as in the above
snippet. Then, at the outer level of the source code
(i.e., not inside any function), include the following statements::

    makecopyandmodify(Immut)
    makemodifyfield(Immut, Array{Immut,1}, 1)

These statements must come after the ``using`` declaration and also after
the definition of ``Immut``.  

The first statement creates all the ``copyandmodify`` methods for the type
(one per field).
The second statement creates the ``modifyField!`` methods for the type for
a particular container (in this case, a 1-dimensional array).  
Include multiple ``makemodifyfield`` calls if  ``Immut`` occurs in other
types of containers (2D arrays, dictionaries, etc).  The other two arguments
to ``makemodifyfield`` are the base type (first argument) and number of subscripts
needed by the container (third argument).  In principle, these other two arguments
are redundant, i.e., it should be possible for ``makemodifyfield`` to deduce the
base type and number of subscripts from the container type, but I couldn't figure
out how to extract this information in a general way when I wrote the package.

These functions ``makecopyandmodify`` and ``makemodifyfield`` are
executed when the module loads; the functions they create (``copyandmodify`` and
``modifyField``) are then available
for use by other routines.




   
