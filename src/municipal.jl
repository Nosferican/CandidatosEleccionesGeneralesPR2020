using Images
using OCReract: run_tesseract
using DataFrames
using CSV

const TEXTBOX_HEIGHT = 94
const TEXTBOX_WIDTH = 320
const COLUMN_WIDTH = 585
const TOP_MARGIN = 650
const LEFT_MARGIN = 550
const CANDIDATURAS = pushfirst!(fill("Legislador", 9), "Alcalde")
adjuntas = Images.load(joinpath("data", "papeletas", "transformaciones", "municipal", "Adjuntas.png"))
aguada = Images.load(joinpath("data", "papeletas", "transformaciones", "municipal", "Aguada.png"))
vieques = Images.load(joinpath("data", "papeletas", "transformaciones", "municipal", "Vieques.png"))

function candidatos_municipales(municipio::AbstractString)
    papeleta = Images.load(joinpath("data", "papeletas", "transformaciones", "municipal", "$municipio"))
    partidos = ["Partido Nuevo Progresista", "Partido Popular Democrático", "Partido Independentista Puertorriqueño"]
    if size(papeleta, 2) == 4200
        partido = papeleta[450:543, 2100:2550]
        push!(partidos,
              titlecase(strip(replace(replace(run_tesseract(partido, lang = "spa"), '\n' => " "), r"\s+" => " "))))
    elseif size(papeleta, 2) ≠ 3300
        throw(ArgumentError("Esta papeleta no parece tener 3-4 afiliaciones"))
    end
    data = DataFrame(Municipio = replace(municipio, ".png" => ""),
                     Afiliación = repeat(partidos, inner = length(CANDIDATURAS)),
                     Candidatura = repeat(CANDIDATURAS, outer = length(partidos)))
    candidatos = String[]
    for afiliación in 0:prevind(partidos, lastindex(partidos))
        for (idx, candidato) in enumerate(vcat(0, 2:10))
            x = TOP_MARGIN + (candidato) * TEXTBOX_HEIGHT
            text_box = papeleta[x:(x + TEXTBOX_HEIGHT),
                                (LEFT_MARGIN + afiliación * COLUMN_WIDTH):(LEFT_MARGIN + afiliación * COLUMN_WIDTH + TEXTBOX_WIDTH)]
            push!(candidatos, strip(replace(replace(run_tesseract(text_box, lang = "spa"), '\n' => " "), r"\s+" => " ")))
        end
    end
    data[!,:Candidato] = candidatos
    data[.!isempty.(data.Candidato),:]
end

municipios = filter!(x -> endswith(x, ".png"), readdir(joinpath("data", "papeletas", "transformaciones", "municipal")))
filter!(x -> replace(x, ".png" => "") ∉ municipales.Municipio, municipios)
municipales = DataFrame(fill(String, 4), [:Municipio, :Afiliación, :Candidatura, :Candidato], 0)
for municipio in municipios
    append!(municipales, candidatos_municipales(municipio))
end

CSV.write(joinpath("data", "municipal.tsv"), municipales, delim = '\t')
