local lp = game:GetService("Players").LocalPlayer
local char = lp.Character

local allLogs = {}
local function logMsg(msg)
    print(msg)
    table.insert(allLogs, msg)
end

local function scanBillboard(bbg)
    logMsg("🔎 BillboardGui Encontrado: " .. bbg.Name)
    logMsg("📁 Caminho: " .. bbg:GetFullName())
    
    local foundText = false
    for _, child in pairs(bbg:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextBox") then
            foundText = true
            logMsg("   📝 [Texto] " .. child.Name .. " -> Valor Atual: '" .. tostring(child.Text) .. "'")
            logMsg("   🔗 Caminho do Texto: " .. child:GetFullName())
        elseif child:IsA("Frame") or child:IsA("ImageLabel") then
            -- Mostra frames/imagens caso seja a barrinha de progresso visual
            logMsg("   🖼️ [" .. child.ClassName .. "] " .. child.Name)
        end
    end
    
    if not foundText then
        logMsg("   ⚠️ Nenhum texto encontrado dentro deste BillboardGui.")
    end
    logMsg("--------------------------------------------------")
end

logMsg("=== INICIANDO VARREDURA 3D (CABEÇA DO BONECO) ===")

if char then
    -- 1. Procura se a barra está dentro do modelo do personagem
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BillboardGui") then
            scanBillboard(v)
        end
    end
else
    logMsg("❌ Erro: Personagem não encontrado.")
end

-- 2. Procura se a barra está no PlayerGui, mas "Adornada" (grudada) no personagem
for _, v in pairs(lp.PlayerGui:GetDescendants()) do
    if v:IsA("BillboardGui") and v.Adornee then
        if char and (v.Adornee == char or v.Adornee:IsDescendantOf(char)) then
            scanBillboard(v)
        end
    end
end

logMsg("=== FIM DA VARREDURA ===")
if setclipboard then
    setclipboard(table.concat(allLogs, "\n"))
    logMsg("✅ Log copiado automaticamente para a sua área de transferência!")
end
