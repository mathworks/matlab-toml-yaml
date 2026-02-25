# Type Coercion

I'm writing down some thoughts here about different ways we can handle the data model differences between YAML/TOML/etc. and MATLAB.

MATLAB is an array based language, meaning everything is an array, even when it's a scalar, it's an array. Even when it cannot be an array, it's still an array at heart. I don't know if there are other languages where this is true, but the data model for almost everything else does not take this approach.

In JSON for example, there are a fixed set of basic types, number, string, object, array, true, false, null. Did I miss any?

Arrays and objects allow you to create structured data files, and this is a pretty useful model to have. It makes interpreting the data and writing utilities pretty simple and I think that's one of the reasons it's become so popular. That, and that it's just javascript code, the internet is written on javascript, and I think people find the internet pretty darn useful.

So now, looking at MATLAB code

```lang=MATLAB
>> x.scalar = 1;
>> x.array = [1]; 
x = 
  struct with fields:
    scalar: 1
     array: 1
```

But for JSON etc, the display we want should be

```lang=MATLAB
x = 
  json with fields:
    scalar: 1
     array: [1]
```

There's a tension with the ease of use in MATLAB where adding a field should just work, so we need to devise a system that sacrifices as little EoU while still enabling full control.

## Option 1: Always Array

Assinging a scalar to a new field always creates an array, and users must specify when something is a scalar

```lang=MATLAB
>> x = json();
>> x.scalar = 1
x = 
  json with fields:
    scalar: [1]
```

Misses the "intuitive" mark.

## Option 2: Infer Intent from RHS

```lang=MATLAB
>> x = json();
>> x.scalar = 1;
>> x.array = [1 2]
>> x.array2 = [0]
x = 
  json with fields:
    scalar: 1
    array:  [1 2]
    array2: 0
```

You really can't infer that the RHS of the 4th line is meant to be an array, and the field name isn't any help either since that's arbitrary.

## Option 3: Pick #1 or #2 and use meaningful typing 

```lang=MATLAB
>> x = json();
>> x.scalar = 1;
>> x.array = [1 2]
>> x.array2 = json.array([0]) % I know no one is going to like the . but I do =P
x = 
  json with fields:
    scalar: 1
    array:  [1 2]
    array2: [0]
```

This lets the user tell us exactly what they want. However, the issue is that `x.array2` is not a native MATLAB type (like double) - it's a wrapped type that remembers "I'm an array". =/

## Option 4: Define a Schema 

In this case, you provide some strong typing for the fields, and then you get the right answer with MATLAB datatypes

```lang=MATLAB
>> x = json(Schema='{    "scalar":"number",    "array": "array"    }');
>> x.scalar = [1 2]
Error assigning to JSON number. Expected a scalar numeric type.
```

But this also causes a weird issue where users cannot tell from inspection that the field is supposed to be a scalar.

```lang=MATLAB
>> 
>> x.("$Schema")
ans = 
JSONSchema: 
    {    
        "scalar": "number",    
        "array": "array"    
    }
```

But this is a sort of "hidden variable" approach that most users won't find intuitive.

