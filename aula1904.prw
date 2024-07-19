#include "totvs.ch"
#include "restful.ch"

user function Aula1907()
    RPCSetEnv("99","01")
return

WSRESTFUL Aula1907 DESCRIPTION "Aula 19/07 Restfull"
    WSDATA codigo   AS String
    WSDATA codbar   AS String

    WSMETHOD GET Produtos DESCRIPTION "Busca tabela de produtos SB1" PATH "/getSB1"
    WSMETHOD POST Produtos DESCRIPTION "Inclui produto SB1" PATH "/postSB1"
END WSRESTFUL

WSMETHOD POST Produtos WSSERVICE Aula1907
    local lRet := .t.
    local cRet := "Registro incluido com sucesso"
    local jBody := jsonObject():New()
    local oModel := FWLoadModel("MATA010")

    cRet := ::GetContent()
    jBody:fromJSON(cRet)

    oModel:SetOperation(3)
    oModel:Activate()

    FWFldPut("B1_COD",      jbody["codigo"])
    FWFldPut("B1_DESC",     JBODY["descricao"])
    FWFldPut("B1_TIPO",     jbody["tipo"])
    FWFldPut("B1_UM",       jbody["um"])
    FWFldPut("B1_LOCPAD",   jbody["local_padrao"])
    FWFldPut("B1_ORIGEM",   jbody["origem"])
    FWFldPut("B1_CODBAR",   jbody["cod_barra"])
    
    if oModel:VldData() .and. oModel:CommitData()
        ::SetResponse("Incluido " + jbody["codigo"])
    else
        SetRestFault(402, varinfo("SB1 Inclusao", oModel:GetErrorMessage()))
        lRet := .f.
    endif
return lRet

WSMETHOD GET Produtos WSRECEIVE codigo, codbar WSSERVICE Aula1907
    local cCond := "%1=1%"
    local cAlias := getNextAlias()
    local lRet := .t.
    local cRet, cUser, cPassw := ""
    local jRet := jsonObject():New()

    default ::codigo := ""
    default ::codbar := ""

    cUser := separa(decode64(substr(::GetHeader('Authorization'),7)),':')[1]
    cPassw := separa(decode64(substr(::GetHeader('Authorization'),7)),':')[2]

    RPCSetEnv("99","01", cUser, cPassw)
    ::SetContentType("application/json")

    if !empty(::codigo)
        cCond := "%b1_cod = '" + ::codigo + "'%"
    elseif !empty(::codbar)
        cCond := "%b1_codbar = '" + ::codbar + "'%"
    endif

    BEGINSQL ALIAS cAlias
        SELECT b1_cod,b1_desc,b1_tipo,b1_locpad,b1_um,b1_origem,b1_codbar
        FROM %TABLE:SB1% SB1
        WHERE B1_FILIAL = %XFILIAL:SB1% AND SB1.%NOTDEL% AND %EXP:cCond%
        ORDER BY B1_FILIAL,B1_COD
    ENDSQL
    dbSelectArea(cAlias)

    if eof()
        SetRestFault(401, "Nenhum registro localizado para o filtro " + cCond)
        lRet := .f.
    else
        jRet["hasNext"] := .f.
        jRet["items"] := {}

        while !eof()
            aAdd(jRet["items"], jsonObject():New())

            aTail(jRet["items"])["codigo"]          := alltrim(b1_cod)
            aTail(jRet["items"])["descricao"]       := alltrim(b1_desc)
            aTail(jRet["items"])["tipo"]            := alltrim(b1_tipo)
            aTail(jRet["items"])["local_padrao"]    := alltrim(b1_locpad)
            aTail(jRet["items"])["unidade_medida"]  := alltrim(b1_um)
            aTail(jRet["items"])["origem"]          := alltrim(b1_origem)
            aTail(jRet["items"])["codigo_barra"]    := alltrim(b1_codbar)
            dbSkip()
        end
        cRet := encodeUTF8(jRet:toJSON())
        ::SetResponse(cRet)
        freeObj(jRet)
    endif
    dbCloseArea()
return lRet
