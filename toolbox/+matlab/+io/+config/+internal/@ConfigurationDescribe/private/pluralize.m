function word = pluralize(singular, count)
%PLURALIZE Return singular or plural form based on count
if count == 1
    word = singular;
else
    word = singular + "s";
end
end
