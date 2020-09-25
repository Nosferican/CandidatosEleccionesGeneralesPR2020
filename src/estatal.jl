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
const CANDIDATURAS_ESTATAL = ["Gobernador", "Comisionado Residente"]
img = Images.load(joinpath("data", "papeletas", "transformaciones", "estatal", "Gobernador y Comisionado Residente.png"))

function estatal(papeleta_estatal::Matrix{<:RGB})
    data = DataFrame(Afiliación = repeat(PARTIDOS, inner = length(CANDIDATURAS_ESTATAL)),
                     Candidatura = repeat(CANDIDATURAS_ESTATAL, outer = length(PARTIDOS)))
    candidatos = String[]
    for afiliación in 0:prevind(PARTIDOS, lastindex(PARTIDOS))
        for (idx, candidato) in enumerate([0, 2])
            x = TOP_MARGIN + (candidato) * TEXTBOX_HEIGHT
            text_box = papeleta_estatal[x:(x + TEXTBOX_HEIGHT),
                                        (LEFT_MARGIN + afiliación * COLUMN_WIDTH):(LEFT_MARGIN + afiliación * COLUMN_WIDTH + TEXTBOX_WIDTH)]
            push!(candidatos, strip(replace(replace(run_tesseract(text_box, lang = "spa"), '\n' => " "), r"\s+" => " ")))
        end
    end
    data[!,:Candidato] = candidatos
    data[.!isempty.(data.Candidato),:]
end

candidatos_estatales = estatal(img)

CSV.write(joinpath("data", "estatal.tsv"), candidatos_estatales, delim = '\t')
