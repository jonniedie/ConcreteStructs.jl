using MacroTools
using MacroTools: postwalk


macro concrete2(expr)
    expr = postwalk(ex->rmlines(ex), expr)
    return if expr.head == :struct
        __parse_struct(expr)
    elseif expr.head == :block || expr.head == :quote
        out = postwalk.(x->isexpr(x) && x.head==:struct ? __parse_struct(x) : x, expr.args)
        esc(block(out...))
    else
        error("bah!")
    end
    
end

function __parse_struct(expr)
    ismutable = expr.args[1]
    if @capture(expr, (struct T_{subs_} <: supes_ fields_ end) | (mutable struct T_{subs_} <: supes_ fields_ end))
        args = (:($T{$subs}<:$supes), fields)
    elseif @capture(expr, (struct T_{subs_} fields_ end) | (mutable struct T_{subs_} fields_ end))
        args = (:($T<:$supes), fields)
    elseif @capture(expr, (struct T_ <: supes_  fields_ end) | (mutable struct T_ <: supes_  fields_ end))
        args = (:($T<:$supes), fields)
    elseif @capture(expr, (struct T_ fields_ end) | (mutable struct T_ fields_ end))
        args = (T, fields)
    else
        error("blarg!")
    end

    return Expr(:struct, ismutable, args...)
end

__parse_field(s::Symbol) = s
function __parse_field(expr::Expr)
    # postwalk(expr) do x
    #     if @capture(x, (field_<:T_ = val_) | (field_::<:T_ = val_))
    #     end
    # end
    # if @capture(expr, (field_<:T_ = val_) | (field_::<:T_ = val_))
    # elseif @capture(expr, field_::T_ = val_)
    # elseif @capture(expr, field_ = val_)
    # elseif @capture(expr, field_::T_)
    # elseif @capture(expr, (field_<:T_) | (field_::<:T_))
    # end
end