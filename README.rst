-----------------------
Modifyfield package
-----------------------

This Julia package provides macros
``@modify_field!`` and ``@modify_tuple_entry!``.  
Macro ``@modify_field!`` 
is intended
to modify a field of an object of an immutable composite type
that sits inside of a container.  To illustrate
the issue, consider the following immutable structure::

   immutable Immut
       intfld::Int
       isadded::Bool
   end

Suppose ``a`` is an array of type ``Immut`` and we wish to perform the following
loop::

   # LOOP 1
   t = 0
   for k = 1 : n
       t += a[k].intfld
       a[k].isadded = true
   end

Unfortunately, the above code snippet is illegal because it modifies a field of an
immutable object.  [Aside: If ``Immut`` had been declared as a plain composite type
with a ``type`` declaration rather than immutable, then the above code ``LOOP 1`` would
be fine.  However, Julia programmers often prefer to put immutable composite types
into containers rather than plain composite types because the former are packed
densely in memory, whereas the latter are accessed via pointers and can be
scattered in memory, yielding poorer performance.]  
Instead, we could obtain the same effect legally via::

   # LOOP 2 
   t = 0
   for k = 1 : n
       t += a[k].intfld
       a[k] = Immut(a[k].intfld, true)
   end

The problem with this code is that it becomes unwieldy for a composite type with
many fields.  In this case, it would be hard to read and also a possible source of bugs
if the arguments were out of order.

To use the macro in the
above example, first include the declaration ``using Modifyfield`` and then write::

   # LOOP 3
   t = 0
   for k = 1 : n
       t += a[k].intfld
       @modify_field! a[k].isadded = true
   end

Thus, the ``@modify_field!`` macro allows for code that mimics the clean syntax of 
``LOOP 1`` above, while
"under the hood"  providing an implementation equivalent to ``LOOP 2`` above.

The original
version of this code was by S. Vavasis and used metaprogramming and the
``Val`` and ``Type`` types of Julia for dispatching to the
correct routine.  It was greatly improved by Simon Byrne
with the incorporation of macros and generated functions.

If the user prefers
to invoke a function rather than a macro, he/she can use the following statement
for the same effect::

   # LOOP 4
   t = 0
   for k = 1 : n
       t += a[k].intfld
       a[k] = copy_and_modify(a[k], Val{:isadded}, true)
   end

Note that although the package is intended for immutable objects in a container, it also
works for immutable objects bound to a plain Julia variable::

  julia> using Modifyfield.@modify_field!

  julia> y = Immut(6,false)
  Immut(6,false)

  julia> @modify_field! y.intfld = 9
  Immut(9,false)

However, for composite types that do not occur inside of larger containers, it 
usually achieves higher performance and is also better style
to declare these as ``type`` rather than ``immutable`` especially if 
one is frequently modifying fields.  


-----------------------
Modifying tuple entries
-----------------------


Similarly, the package provides a macro for modifying tuple entries.  Here
is an example of its execution::

    julia> using Modifyfield.@modify_tuple_entry!

    julia> t = (5,9.5,true)
    (5,9.5,true)

    julia> @modify_tuple_entry! t[2] = false
    (5,false,true)

There is also an equivalent functional call in case the programmer prefers functions
to macros::
   
    julia> using Modifyfield.copy_and_modify_tup

    julia> t = (5,9.5,true)
    (5,9.5,true)

    julia> t = copy_and_modify_tup(t, Val{2}, true)
    (5,true,true)

As in the case of immutables, the implementation of ``@modify_tuple_entry!`` actually
copies the entire tuple over.

A couple of cautionary notes are in order.  First, both the macro ``@modify_tuple_entry!``
and the function-call ``copy_and_modify_tup``
require the subscript (which is 2 in the above
example) to be a literal integer; a variable or more general expression may not
be used.  Second, the main purpose of this macro is again for tuples that are
packed inside of some other container in a high-performance setting.  If one is
modifying bare tuples such as ``t`` in the above example, then in most cases
a cell array (``Array{Any,1}``) would be preferable to a tuple.





   
