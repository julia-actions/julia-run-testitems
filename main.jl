using TestItemRunner2, JSON

function esc_data(s)
    s = replace(s, '%' => "%25")
    s = replace(s, '\r' => "%0D")
    s = replace(s, '\n' => "%0A")
    return s
end

juliaup_channel = ENV["TEST_JULIAUP_CHANNEL"]

const os = if Sys.iswindows()
    "Windows"
elseif Sys.isapple()
    "MacOS"
elseif Sys.islinux()
    "Linux"
else
    error("Unknown platform")
end

results = run_tests(
    pwd(),
    environments=[TestEnvironment("Julia $juliaup_channel:$os", true, Dict{String,Any}("JULIAUP_CHANNEL" => juliaup_channel,"JULIA_DEPOT_PATH" => nothing))],
    fail_on_detection_error=false,
    return_results=true,
    print_failed_results=true,
    progress_ui=:log    
)

at_least_one_fail = false

for ti in results.testitems
    for p in ti.profiles
        if p.status !="passed"
            at_least_one_fail = true
            break
        end
    end
end

# for te in results.definition_errors
#     global at_least_one_fail = true
#     println()
#     println("::error file=$(TestItemRunner2.uri2filepath(TestItemRunner2.URI(te.uri))),line=$(te.line),title=Test definition error::$(esc_data(te.message))")
# end

# for result in results.test_results
#     if result.result.status!="passed"
#         global at_least_one_fail = true
#         for message in result.result.message
#             println()
#             println("::error file=$(TestItemRunner2.uri2filepath(TestItemRunner2.URI(message.location.uri))),line=$(message.location.range.start.line),endLine=$(message.location.range.stop.line),title=Test failure on $(result.testenvironment.name)::$(esc_data(message.message))")
#         end
#     end
# end

# exported_results = [
#     Dict("uri" => string(i.testitem.uri), "name" => i.testitem.detail.name, "status" => i.result.status) for i in results.test_results
# ]

exported_results = results

JSON.lower(uri::TestItemRunner2.URI) = string(uri)

println("The JSON IS")
JSON.print(exported_results)

if haskey(ENV, "RESULTS_PATH")
    open(ENV["RESULTS_PATH"], "w") do f
        JSON.print(f, exported_results)
    end
end

println()
println("NOW SHOWING SOME PROC DIAG")
println()
println()
print_process_diag()

# open(ENV["GITHUB_STEP_SUMMARY"], "w") do f
#     println(f, "# Test summary from David")
# end

if at_least_one_fail
    exit(1)
end
