#include "totvs.ch"
#include "RestFul.ch"

WSRESTFUL AdvplRest DESCRIPTION "Treinamento Advpl Webservice"
    WSDATA CNPJ_CPF AS String OPTIONAL
    WSDATA codigo   AS String OPTIONAL
    WSDATA loja     AS String OPTIONAL

    WSMETHOD GET Clientes ;
        DESCRIPTION "Obtem a lista de clientes cadastrados via CPF ou CNPJ" ;
        PATH "/clientes"
    
    WSMETHOD POST Pedidos ;
        DESCRIPTION "Inclusao de pedido de venda" ;
        PATH "/pedidos"
END WSRESTFUL

WSMETHOD POST Pedidos WSSERVICE AdvplRest
    local nIts AS Numeric, aItens, aLinha, aCabec
    local jPedido  := jsonObject():New()
    
    ::SetContentType("application/json")
    jPedido:fromJSON(::GetContent()) // Pedidos no body da requisição

    aCabec := {}
    aadd(aCabec, {"C5_CLIENTE", jPedido["cliente"],     nil})
    aadd(aCabec, {"C5_LOJA",    jPedido["loja"],        nil})
    aadd(aCabec, {"C5_CONDPAG", jPedido["cond_pagto"],  nil})
    aadd(aCabec, {"C5_TPFRETE", jPedido["tipo_frete"],  nil})
    
    aItens := {}
    for nIts := 1 to len(jPedido["itens"])
        aLinha := {}
        aadd(aLinha, {"C6_PRODUTO", jPedido["itens"][nIts]["codigo"],      nil})
        aadd(aLinha, {"C6_PRODUTO", jPedido["itens"][nIts]["quantidade"],  nil})
        aadd(aLinha, {"C6_PRODUTO", jPedido["itens"][nIts]["preco"],       nil})
        aadd(aLinha, {"C6_PRODUTO", jPedido["itens"][nIts]["TES"],         nil})
        aadd(aItens, aLinha)
    next nIts
    freeObj(jPedido)

    BEGIN TRANSACTION
        lMsErroAuto := .f.
        MSExecAuto({|a,b,c,d| MATA410(a,b,c,d)}, aCabec, aItens, 3)          

        If lMsErroAuto
            SetRestFault(402, "Erro na inclusao do Pedido de venda") //MOSTRAERRO()
            RollBackSX8()
            DisarmTransaction()
        Else
            ConfirmSX8()
            ::SetResponse("{'pedido': '" + SC5->C5_NUM + "'}")
        EndIf
    END TRANSACTION
return .t.

WSMETHOD GET Clientes WSRECEIVE CNPJ_CPF, codigo, loja WSSERVICE AdvplRest
    local cAlias := GetNextAlias()
    local cWhere := "%1<>1%"
    local jRet   := jsonObject():New()

    default ::CNPJ_CPF := ""
    default ::codigo := ""
    default ::loja := ""

    if empty(::CNPJ_CPF + ::codigo + ::loja)
        cWhere := "%1=1%"
    elseif !empty(::CNPJ_CPF)
        cWhere := "%A1_CGC='" + ::CNPJ_CPF + "'%"
    elseif !empty(::codigo) .and. !empty(::loja)
        cWhere := "%A1_COD='" + ::codigo + "' AND A1_LOJA='" + ::loja + "'%"
    endif
    RPCSetEnv("99", "01")

    BEGINSQL ALIAS cAlias
        SELECT A1_COD,A1_LOJA,A1_NOME,A1_PESSOA,A1_END,A1_CGC
        FROM %TABLE:SA1% SA1
        WHERE A1_FILIAL = %XFILIAL:SA1% AND %NOTDEL% AND %exp:cWhere%
        ORDER BY A1_COD,A1_LOJA
    ENDSQL
    if (cAlias)->(eof())
        SetRestFault(402, "Nenhum registro localizado")
        return .f.
    endif
    jRet["itens"] := {}

    while (cAlias)->(!eof())
        aAdd(jRet["itens"], jsonObject():New())
        aTail(jRet["itens"])["codigo"]   := (cAlias)->A1_COD
        aTail(jRet["itens"])["loja"]     := (cAlias)->A1_LOJA
        aTail(jRet["itens"])["nome"]     := rtrim((cAlias)->A1_NOME)
        aTail(jRet["itens"])["tipo"]     := (cAlias)->A1_PESSOA
        aTail(jRet["itens"])["endereco"] := rtrim((cAlias)->A1_END)
        (cAlias)->(dbSkip())
    end
    (cAlias)->(dbCloseArea())

    ::SetContentType("application/json")
    ::SetResponse(encodeUTF8(jRet:toJSON()))

    freeObj(jRet)
    RPCClearEnv()
return .t.
