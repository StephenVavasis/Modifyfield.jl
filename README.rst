-----------------------
Modifyfield package
-----------------------

This Julia package provides macros
``@modify_field!``, ``@modify_fields!``  and ``@modify_tuple_entry!``.  
Macro ``@modify_field!`` 
is intended
to modify a field of an object of an immutable composite type
that sits inside of a container.  To illustrate
the issue, consider the following immutable structure::

   immutable Immut
       intfld::Int
       isadded::Bool
   end

Suppose ``a`` is an array of type ``Immut`` and the following
loop is needed::

   # LOOP 1
   t = 0
   for k = 1 : n
       t += a[k].intfld
       a[k].isadded = true
   end

Unfortunately, the above code snippet is illegal because it modifies a field of an
immutable object.  [Aside: If ``Immut`` had been declared as a plain composite type
with a ``type`` declaration rather than immutable, then the above code ``LOOP 1`` would
be fine.  However, Julia programmers often put immutable composite types
into containers rather than plain composite types because the former are packed
densely in memory which may yield better performance.]
Instead, we could obtain the same effect legally via::

   # LOOP 2 
   t = 0
   for k = 1 : n
       t += a[k].intfld
       a[k] = Immut(a[k].intfld, true)
   end

The problem with this code is that it becomes unwieldy for a composite type with
many fields.  In this case, it would be hard to read and also a possible source of bugs
if the arguments to the ``Immut`` constructor were ordered incorrectly.

To use the macro in the
above example, first include the declaration ``using Modifyfield`` and then write::

   # LOOP 3
   t = 0
   for k = 1 : n
       t += a[k].intfld
       @modify_field! a[k].isadded = true
   end

Thus, the ``@modify_field!`` macro allows for code that mimics the clean syntax of 
``LOOP 1`` above while
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

Note that although the macro 
is intended for immutable objects in a container, it also
works for immutable objects bound to a plain Julia variable::

  julia> using Modifyfield.@modify_field!

  julia> y = Immut(6,false)
  Immut(6,false)

  julia> @modify_field! y.intfld = 9
  Immut(9,false)

However, for composite types that do not occur inside of larger containers, 
higher performance is
usually attained 
by declaring objects such as this as
a ``type`` rather than ``immutable`` especially if 
one is frequently modifying fields.  (A ``type`` rather than ``immutable``
is also stylistically preferred in this context.)

-------------------------
Modifying multiple fields
-------------------------

A macro is also provided for modifying multiple fields at the
same time.  (This is more efficient than modifying one at a time.)
Here is an example of its usage::

   immutable Immut2
       intfld::Int
       isadded::Bool
       xx::Float64
   end

If ``a`` is an array of ``Immut2`` entries, then the following
loop changes the first two fields of each entry::

   for k = 1 : n
       @modify_fields! a[k].(intfld = k+1, isadded = true)
   end

This slightly odd syntax was chosen
so that field names are close to their corresponding new values
to improve readability.

The parenthesized argument in the ``@modify_fields!`` macro can
name a single field, but in this case it should be followed by
a comma (so that its syntax matches the Julia tuple syntax)::
     @modify_fields! w.(intfld = 6,)
which is equivalent to::
     @modify_field! w.intfld = 6


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

There is also an equivalent functional call::
  
    julia> using Modifyfield.copy_and_modify_tup

    julia> t = (5,9.5,true)
    (5,9.5,true)

    julia> t = copy_and_modify_tup(t, Val{2}, true)
    (5,true,true)

As in the case of immutables, the implementation of
``@modify_tuple_entry!`` actually copies the entire tuple over.

A couple of cautionary notes are in order.  First, the macro
``@modify_tuple_entry!``
requires a literal integer for the subscript 
(which is 2 in the above example) of the tuple.
A variable or more general expression may not be
used.  
The function-call version ``copy_and_modify_tup`` can take a variable
subscript, e.g., ``Val{j}`` as its second argument, but this leads
to a loss of performance because the compiler cannot fully
determine argument types, and therefore the method dispatch happens at
run time. 

Second, the main purpose of this macro is for tuples that
are packed inside of some other container in a high-performance
setting.  If one is modifying bare tuples such as ``t`` in the above
example, then in most cases a cell array (``Array{Any,1}``) would be
preferable to a tuple.





   
