#include "totvs.ch"
#include "RestFul.ch"

WSRESTFUL AdvplRest DESCRIPTION "Treinamento Advpl Webservice"
    WSDATA CNPJ_CPF AS String OPTIONAL
    WSDATA codigo   AS String OPTIONAL
    WSDATA loja     AS String OPTIONAL
    
    WSMETHOD GET Clientes DESCRIPTION "Obtem a lista de clientes cadastrados via CPF ou CNPJ" PATH "/clientes"
    WSMETHOD POST Pedidos DESCRIPTION "Inclusao de pedido de venda" PATH "/pedidos"
END WSRESTFUL

WSMETHOD POST Pedidos WSRECEIVE CNPJ_CPF, codigo, loja WSSERVICE AdvplRest
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
    jRet["items"] := {}

    while (cAlias)->(!eof())
        aAdd(jRet["items"], jsonObject():New())
        aTail(jRet["items"])["codigo"]   := (cAlias)->A1_COD
        aTail(jRet["items"])["loja"]     := (cAlias)->A1_LOJA
        aTail(jRet["items"])["nome"]     := rtrim((cAlias)->A1_NOME)
        aTail(jRet["items"])["tipo"]     := (cAlias)->A1_PESSOA
        aTail(jRet["items"])["endereco"] := rtrim((cAlias)->A1_END)
        (cAlias)->(dbSkip())
    end
    (cAlias)->(dbCloseArea())

    ::SetContentType("application/json")
    ::SetResponse(encodeUTF8(jRet:toJSON()))

    freeObj(jRet)
    RPCClearEnv()
return .t.
