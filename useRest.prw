#include "totvs.ch"

user function RestClient()
    local oRest := FWREST():New("http://localhost:8080/advplrest")
    local cRet  AS Character
    local jRet := jsonObject():New()
    local aClientes AS Array
    local aHead := {"Authorization: Basic YWRtaW46MQ=="}

    // busca clientes
    oRest:SetPath("/clientes")

    if oRest:Get(aHead)
        cRet := oRest:GetResult()
    else
        cRet := oRest:GetLastError()
    endif
    
    if empty(cRet := jRet:fromJSON(cRet))
        aClientes := jRet["itens"]
    else
        alert(cRet)
    endif
    freeObj(jRet)
    jRet := jsonObject():New()

    // grava pedido de venda
    oRest:SetPath("/pedidos")

    jRet["cliente"] := "000001"
    jRet["loja"] := "01"
    jRet["cond_pagto"] := "001"
    jRet["tipo_frete"] := "F"
    jRet["itens"] := {}
    aAdd(jRet["itens"], jsonObject():New())
    aTail(jRet["itens"])["codigo"] := "PRD1"
    aTail(jRet["itens"])["quantidade"] := "PRD1"
    aTail(jRet["itens"])["preco"] := "PRD1"
    aTail(jRet["itens"])["TES"] := "PRD1"
    
    oRest:SetPostParams(jRet:toJSON())

    if oRest:Post(aHead)
        cRet := oRest:GetResult()
    else
        cRet := oRest:GetLastError()
    endif
return
