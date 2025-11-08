using TestItemRunner2, JSON, Logging

if ARGS[1] == "nodebug"
    global_logger(ConsoleLogger(Warn))
elseif ARGS[1] == "debug"
    ENV["JULIA_DEBUG"] = "Main,TestItemRunner2,TestItemControllers"
else
    error("Unknown command line argument $(ARGS[1]).")
end

@info "WE ARE ON v2"

println("THE CONTENT OF THE ENV IS ", ENV["TEST_ENV"])

env_dict = Dict{String,Any}()

if ENV["TEST_ENV"] != ""
    for (k,v) in JSON.parse(ENV["TEST_ENV"])
        env_dict[k] = v
    end
end

function esc_data(s)
    s = replace(s, '%' => "%25")
    s = replace(s, '\r' => "%0D")
    s = replace(s, '\n' => "%0A")
    return s
end

juliaup_channel = ENV["TEST_JULIAUP_CHANNEL"]

env_dict["JULIAUP_CHANNEL"] = juliaup_channel
env_dict["JULIA_DEPOT_PATH"] = nothing

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
    fail_on_detection_error=false,
    return_results=true,
    print_failed_results=true,
    progress_ui=:log,
    timeout=20*60
)

at_least_one_fail = false

for ti in results.testitems
    for p in ti.profiles
        if p.status != :passed
            global at_least_one_fail = true
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

if haskey(ENV, "RESULTS_PATH")
    open(ENV["RESULTS_PATH"], "w") do f
        JSON.print(f, exported_results)
    end
end

# println()
# println("NOW SHOWING SOME PROC DIAG")
# println()
# println()
# print_process_diag()

# TestItemRunner2.kill_controller()

# open(ENV["GITHUB_STEP_SUMMARY"], "w") do f
#     println(f, "# Test summary from David")
# end

if at_least_one_fail
    exit(1)
end
