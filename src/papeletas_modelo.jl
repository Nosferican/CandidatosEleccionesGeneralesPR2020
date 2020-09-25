using HTTP: escapeuri
using Unicode: normalize
using Cascadia: parsehtml, Selector, getattr, nodeText, HTMLElement
using OCReract: Images, run_tesseract
using ImageMagick_jll: imagemagick_convert

"""
    papeletas_por_juridicción(juridicción::HTMLElement{:tbody})::Nothing
"""
function papeletas_por_juridicción(juridicción::HTMLElement{:tbody})
    municipio = strip(nodeText(juridicción[1][1]))
    municipal = juridicción[1][2][1].attributes["href"]
    legislativas = [ papeleta.children[2][1].attributes["href"] for papeleta in juridicción.children[2:end] ]
    if !isfile(joinpath("data", "papeletas", "original", "municipal", "$municipio.pdf"))
        download(string("http://www.ceepur.org/Elecciones/",
                        replace(municipal,
                                r"(?<=\d{3}_).*(?=_MUN)" => escapeuri(normalize(municipio, stripmark = true)))),
                 joinpath("data", "papeletas", "original", "municipal", "$municipio.pdf"))
    end
    for legislativa in legislativas
        if !isfile(joinpath("data", "papeletas", "original", "legislativa", "$(legislativa[16:18]).pdf"))
            download(string("http://www.ceepur.org/Elecciones/",
                            replace(legislativa,
                                    r"(?<=\d{3}_).*(?=__LEG)" => escapeuri(normalize(municipio, stripmark = true)))),
                     joinpath("data", "papeletas", "original", "legislativa", "$(legislativa[16:18]).pdf"))
        end
    end
end

isdir(joinpath("data", "papeletas")) || mkdir(joinpath("data", "papeletas"))
isdir(joinpath("data", "papeletas", "original")) || mkdir(joinpath("data", "papeletas", "original"))
isdir(joinpath("data", "papeletas", "original", "estatal")) || mkdir(joinpath("data", "papeletas", "original", "estatal"))
isdir(joinpath("data", "papeletas", "original", "municipal")) || mkdir(joinpath("data", "papeletas", "original", "municipal"))
isdir(joinpath("data", "papeletas", "original", "legislativa")) || mkdir(joinpath("data", "papeletas", "original", "legislativa"))
isfile(joinpath("data", "papeletas", "original", "papeletas.html")) ||
    download("http://www.ceepur.org/Elecciones/Papeletas.html", joinpath("data", "papeletas", "original", "papeletas.html"))
papeletas = parsehtml(String(read(joinpath("data", "papeletas", "original", "papeletas.html"))))
jurisdicciones = eachmatch(Selector("tbody"), papeletas.root)
isfile(joinpath("data", "papeletas", "original", "estatal", "$(nodeText(jurisdicciones[1][1][2])).pdf")) ||
    download("http://www.ceepur.org/Elecciones/$(jurisdicción[1][1][2][1].attributes["href"])",
             joinpath("data", "papeletas", "original", "estatal", "$(nodeText(jurisdicciones[1][1][2])).pdf"))
foreach(papeletas_por_juridicción, @view(jurisdicciones[2:end]))

isdir(joinpath("data", "papeletas", "transformaciones")) || mkdir(joinpath("data", "papeletas", "transformaciones"))
isdir(joinpath("data", "papeletas", "transformaciones", "estatal")) || mkdir(joinpath("data", "papeletas", "transformaciones", "estatal"))
isdir(joinpath("data", "papeletas", "transformaciones", "municipal")) || mkdir(joinpath("data", "papeletas", "transformaciones", "municipal"))
isdir(joinpath("data", "papeletas", "transformaciones", "legislativa")) || mkdir(joinpath("data", "papeletas", "transformaciones", "legislativa"))

for papeleta in ["estatal", "legislativa", "municipal"]
    for filename in filter!(filename -> endswith(filename, ".pdf"),readdir(joinpath("data", "papeletas", "original", papeleta)))
        outfile = replace(joinpath("data", "papeletas", "transformaciones", papeleta, filename), r"df$" => "ng")
        if !isfile(outfile)
            imagemagick_convert() do exe_path
                infile = joinpath("data", "papeletas", "original", papeleta, filename)
                run(`$exe_path -density 300 "$infile[0]" "$outfile"`)
            end
        end
    end
end
