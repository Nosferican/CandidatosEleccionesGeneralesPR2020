using Images
using OCReract: run_tesseract
using DataFrames
using CSV

const TEXTBOX_HEIGHT = 94
const TEXTBOX_WIDTH = 320
const COLUMN_WIDTH = 585
const TOP_MARGIN = 650
const LEFT_MARGIN = 550
const PARTIDOS = ["Partido Nuevo Progresista", "Partido Popular Democrático", "Partido Independentista Puertorriqueño",
                  "Movimiento Victoria Ciudadana", "Proyecto Dignidad", ""]
const CANDIDATURAS_LEGISLATIVAS_REGIONALES = ["Representante", "Senador", "Senador"]

distritios = CSV.read(joinpath("data", "distritos.tsv"), DataFrame)
precintos_electorales = combine(first, groupby(distritios, :Representativo))

function representantes_por_distrito(distrito_representativo::Integer)
    precinto = precintos_electorales.Electoral[findfirst(isequal(distrito_representativo), precintos_electorales.Representativo)]
    papeleta = Images.load(joinpath("data", "papeletas", "transformaciones", "legislativa", "$(lpad(precinto, 3, '0')).png"))
    data = DataFrame(Afiliación = PARTIDOS,
                     Candidatura = "Representante",
                     Distrito = distrito_representativo)
    candidatos = String[]
    for afiliación in 0:prevind(PARTIDOS, lastindex(PARTIDOS))
        text_box = papeleta[TOP_MARGIN:(TOP_MARGIN + TEXTBOX_HEIGHT),
                            (LEFT_MARGIN + afiliación * COLUMN_WIDTH):(LEFT_MARGIN + afiliación * COLUMN_WIDTH + TEXTBOX_WIDTH)]
        push!(candidatos, strip(replace(replace(run_tesseract(text_box, lang = "spa"), '\n' => " "), r"\s+" => " ")))
    end
    data[!,:Candidato] = candidatos
    data[.!isempty.(data.Candidato),:]
end
function senadores_por_distrito(distrito_senatorial::Integer)
    precinto = precintos_electorales.Electoral[findfirst(isequal(distrito_senatorial), precintos_electorales.Senatorial)]
    papeleta = Images.load(joinpath("data", "papeletas", "transformaciones", "legislativa", "$(lpad(precinto, 3, '0')).png"))
    data = DataFrame(Afiliación = repeat(PARTIDOS, inner = 2),
                     Candidatura = "Senador",
                     Distrito = distrito_senatorial)
    candidatos = String[]
    for afiliación in 0:prevind(PARTIDOS, lastindex(PARTIDOS))
        for (idx, candidato) in enumerate(2:3)
            x = TOP_MARGIN + (candidato) * TEXTBOX_HEIGHT
            text_box = papeleta[x:(x + TEXTBOX_HEIGHT),
                                (LEFT_MARGIN + afiliación * COLUMN_WIDTH):(LEFT_MARGIN + afiliación * COLUMN_WIDTH + TEXTBOX_WIDTH)]
            push!(candidatos, strip(replace(replace(run_tesseract(text_box, lang = "spa"), '\n' => " "), r"\s+" => " ")))
        end
    end
    data[!,:Candidato] = candidatos
    data[.!isempty.(data.Candidato),:]
end

distritos_representativos = DataFrame([String, String, UInt8, String], [:Afiliación, :Candidatura, :Distrito, :Candidato], 0)
for distrito_representativo in precintos_electorales.Representativo
    append!(distritos_representativos, representantes_por_distrito(distrito_representativo))
end

distritos_senatoriales = DataFrame([String, String, UInt8, String], [:Afiliación, :Candidatura, :Distrito, :Candidato], 0)
for distritos_senatorial in unique(precintos_electorales.Senatorial)
    append!(distritos_senatoriales, senadores_por_distrito(distritos_senatorial))
end

function candidatos_por_acumulación()
    papeleta = Images.load(joinpath("data", "papeletas", "transformaciones", "legislativa", "001.png"))
    data = DataFrame(Afiliación = repeat(PARTIDOS, inner = 12),
                     Candidatura = repeat(vcat(fill("Representante", 6), fill("Senador", 6)), outer = length(PARTIDOS)),
                     Distrito = 0)
    candidatos = String[]
    for afiliación in 0:prevind(PARTIDOS, lastindex(PARTIDOS))
        for (idx, candidato) in enumerate(vcat(5:10, 12:17))
            x = TOP_MARGIN + (candidato) * TEXTBOX_HEIGHT
            text_box = papeleta[x:(x + TEXTBOX_HEIGHT),
                                (LEFT_MARGIN + afiliación * COLUMN_WIDTH):(LEFT_MARGIN + afiliación * COLUMN_WIDTH + TEXTBOX_WIDTH)]
            push!(candidatos, strip(replace(replace(run_tesseract(text_box, lang = "spa"), '\n' => " "), r"\s+" => " ")))
        end
    end
    data[!,:Candidato] = candidatos
    data[.!isempty.(data.Candidato),:]
end

por_acumulación = candidatos_por_acumulación()

legislativa = vcat(por_acumulación, distritos_representativos, distritos_senatoriales)
sort!(legislativa)

CSV.write(joinpath("data", "legislativa.tsv"), legislativa, delim = '\t')
