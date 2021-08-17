-- Automatic...ish tests for api methods
if not minetest.global_exists('test') then return end

local describe = test.describe
local it = test.it
local stub = test.stub
local before_each = test.before_each
local after_all = test.after_all
local assert_equal = test.assert.equal
local assert_not_equal = test.assert.not_equal
local expect_error = test.expect.error

local api = gravelsieve.api

describe("gravelsieve", function ()
    local log_stub = stub()
    local original_log = gravelsieve.log
    gravelsieve.log = log_stub.call
    local log_called_times = log_stub.called_times
    local log_called_with = log_stub.called_with

    after_all(function ()
        gravelsieve.log = original_log
    end)

    describe("probability api", function ()

        describe("report_probabilities", function ()
            it("prints out correct values", function ()
                api.report_probabilities({
                    test1 = 1,
                    test2 = 2,
                    test3 = 4
                })
                log_called_times(5)
                log_called_with("action", "ore probabilities:")
                log_called_with("action", "%-32s: 1 / %.02f", "test1", 1)
                log_called_with("action", "%-32s: 1 / %.02f", "test2", 0.5)
                log_called_with("action", "%-32s: 1 / %.02f", "test3", 0.25)
                log_called_with("action", "Overall probability %f", 7)
            end)
        end)

        describe("sum_probabilities", function ()
            it("properly adds up all values in table", function ()

                local sum_result = api.sum_probabilities({
                    test1 = 1,
                    test2 = 2,
                    test3 = 4
                })

                assert_equal(sum_result, 7, "Sum should equal 7")
            end)
        end)

        describe("scale_probabilities", function ()
            it("properly scales up probabilities", function ()

                local doubled_probabilities = api.scale_probabilities({
                    test1 = 1,
                    test2 = 2,
                    test3 = 4
                }, 2)

                assert_equal(api.sum_probabilities(doubled_probabilities), 14, "Scaled up probabilities should sum to total")
                assert_equal(doubled_probabilities, {
                    test1 = 2,
                    test2 = 4,
                    test3 = 8
                }, "Probabilities should be properly scaled up")
            end)
        end)

        describe("scale_probabilities_to_fill", function ()
            it("properly scales up probabilities", function ()

                local doubled_probabilities = api.scale_probabilities_to_fill({
                    test1 = 1,
                    test2 = 2,
                    test3 = 4
                }, 14)

                assert_equal(api.sum_probabilities(doubled_probabilities), 14, "Scaled up probabilities should sum to total")
                assert_equal(doubled_probabilities, {
                    test1 = 2,
                    test2 = 4,
                    test3 = 8
                }, "Probabilities should be properly scaled up")
            end)

            it("properly scales down probabilities", function ()

                local normalized_probabilities = api.scale_probabilities_to_fill({
                    test1 = 1,
                    test2 = 2,
                    test3 = 4
                }, 1)

                assert_equal(api.sum_probabilities(normalized_probabilities), 1, "Scaled down probabilities should sum to total")
                assert_equal(normalized_probabilities, {
                    test1 = 1/7,
                    test2 = 2/7,
                    test3 = 4/7
                }, "Probabilities should be properly scaled down")
            end)
        end)
        
        describe("merge_probabilities", function ()

            it("merges unique tables", function ()

                local input1 = {
                    test1 = 1,
                    test2 = 2,
                    test3 = 4
                }
                local input2 = {
                    test4 = 1,
                    test5 = 2,
                    test6 = 4
                }
                local output = {
                    test1 = 1,
                    test2 = 2,
                    test3 = 4,
                    test4 = 1,
                    test5 = 2,
                    test6 = 4
                }

                local result = api.merge_probabilities(input1, input2)

                assert_equal(result, output, "Probabilities should be properly merged")
            end)

            it("will add up similar values in tables", function ()

                local input1 = {
                    test1 = 1,
                    test2 = 2,
                    test3 = 4
                }
                local input2 = {
                    test2 = 1,
                    test3 = 2,
                    test4 = 4
                }
                local output = {
                    test1 = 1,
                    test2 = 3,
                    test3 = 6,
                    test4 = 4
                }

                local result = api.merge_probabilities(input1, input2)

                assert_equal(result, output, "Probabilities should be properly merged")
            end)

            it("can merge several tables", function ()
                local input1 = {
                    test1 = 1,
                    test2 = 2,
                    test3 = 4
                }
                local input2 = {
                    test2 = 1,
                    test3 = 2,
                    test4 = 4
                }
                local input3 = {
                    test4 = 1,
                    test5 = 2,
                    test6 = 4
                }
                local output = {
                    test1 = 1,
                    test2 = 3,
                    test3 = 6,
                    test4 = 5,
                    test5 = 2,
                    test6 = 4
                }

                local result = api.merge_probabilities(input1, input2, input3)

                assert_equal(result, output, "Probabilities should be properly merged")
            end)

        end)

    end)

    describe("config api", function ()
                
        before_each(function ()
            api.reset_config()
        end)

        after_all(function ()
            api.reset_config()
        end)

        describe("can_process", function ()

            it("returns true if an input exists", function ()
                api.register_input("default:gravel")
                local registered = api.can_process("default:gravel")

                assert_equal(registered, true, "Should return correctly")
            end)

            it("returns false if an input does not exist", function ()
                local registered = api.can_process("default:gravel")

                assert_equal(registered, false, "Should return correctly")
            end)
        end)

        describe("get_outputs", function ()

            it("returns the outputs of an input", function ()

                local output = {
                    ["default:gravel"] = 1,
                    ["default:sand"] = 1,
                    ["default:coal_lump"] = 0.1
                }
                api.register_input("default:gravel", output)

                local registered_output = api.get_outputs("default:gravel", "relative")

                assert_equal(registered_output, output, "Output should be properly retrieved")
            end)

            it("does not allow modification of interal variable", function ()
                local output = {
                    ["default:gravel"] = 1,
                    ["default:sand"] = 1,
                    ["default:coal_lump"] = 0.1
                }

                api.register_input("default:gravel", output)

                local registered_output1 = api.get_outputs("default:gravel", "relative")
                registered_output1["default:gravel"] = 100
                local registered_output2 = api.get_outputs("default:gravel", "relative")

                assert_not_equal(registered_output1, registered_output2, "Output should not be modified")
                assert_equal(registered_output2, output, "Original output should remain the same when modified")
            end)
        end)

        describe("register_input", function ()
            it("registers an input with no output", function ()
                api.register_input("default:gravel")
                local registered_output = api.get_outputs("default:gravel", "relative")

                assert_equal(registered_output, {}, "Should be registered properly")
            end)

            it("registers an input with a string output", function ()
                api.register_input("default:gravel", "default:sand")
                local registered_output = api.get_outputs("default:gravel", "relative")

                assert_equal(registered_output, {["default:sand"] = 1}, "Should be registered properly")
            end)

            it("registers an input with a table output", function ()
                local output = {
                    ["default:gravel"] = 1,
                    ["default:sand"] = 1,
                    ["default:coal_lump"] = 0.1
                }
                api.register_input("default:gravel", output)

                local registered_output = api.get_outputs("default:gravel", "relative")

                assert_equal(registered_output, output, "Should be registered properly")
            end)

            it("does not allow a previously registered input to be registered again", function ()
                expect_error("re-registering input \"default:gravel\"")

                api.register_input("default:gravel")
                api.register_input("default:gravel")
            end)

            -- it("does allow a previously registered input to be registered again if allow_override is switched on", function ()
            --     api.register_input("default:gravel")
            --     api.register_input("default:gravel", {}, true)
            -- end)

            it("does allow a previously registered input to be registered again", function ()
                api.register_input("default:gravel")
                api.override_input("default:gravel")
            end)

            it("does not allow an invalid input to be registered", function ()
                expect_error("attempt to register unknown node \"garbage_nonsense\"")

                api.register_input("garbage_nonsense")
            end)

            it("does not allow an invalid output to be registered", function ()
                expect_error("attempt to register unknown node \"garbage_nonsense\"")

                api.register_input("default:gravel", "garbage_nonsense")
            end)

            it("does not allow an invalid output type to be used", function ()
                expect_error("Gravelsieve outputs must be a table or a string")

                api.register_input("default:gravel", 28465)
            end)
        end)

        describe("remove_input", function ()
            it("removes an input from the config", function ()
                api.register_input("default:gravel", "default:sand")
                api.remove_input("default:gravel")

                assert_equal(api.can_process("default:gravel"), false, "Should be properly removed")
            end)

            it("informs you if an unregistered input is removed", function ()
                api.remove_input("default:gravel")

                log_called_times(1)
                log_called_with("error", "Cannot remove an input (%s) that does not exist.", "default:gravel")
            end)

            it("returns the registered output of the input", function ()
                local output = {["default:sand"]=1}
                api.register_input("default:gravel", output)
                local registered_output = api.remove_input("default:gravel")

                assert_equal(registered_output, {relative=output,dynamic={},fixed={}}, "Should return proper result")
            end)
        end)

        describe("swap_input", function ()

            it("deletes the old input", function ()
                api.register_input("default:gravel")
                api.swap_input("default:gravel", "default:sand")

                assert_equal(api.can_process("default:gravel"), false, "Should be properly deleted")
            end)

            it("creates the new input with the same output", function ()
                local output = {["default:sand"]=1}
                api.register_input("default:gravel", output)
                api.swap_input("default:gravel", "default:sand")
                local registered_output = api.get_outputs("default:sand", "relative")

                assert_equal(registered_output, output, "Should be properly swapped")
            end)
        end)


        describe("register_output", function ()
            it("registers an output to an input", function ()
                api.register_input("default:gravel")
                api.register_output("default:gravel", "default:sand", 0.1)
                local registered_output = api.get_outputs("default:gravel", "relative")

                assert_equal(registered_output, {["default:sand"]=0.1}, "Output should be registered properly")
            end)

            it("informs you if you register an output to a non existent input", function ()
                api.register_output("default:gravel", "default:sand", 0.1)

                log_called_times(1)
                log_called_with("error", "You must register the input (%s) before registering the output (%s).", "default:gravel", "default:sand")
            end)

            it("does not allow a previously registered output to be registered again", function ()
                expect_error("re-registering relative output \"default:gravel\" for \"default:sand\"")

                api.register_input("default:gravel", "default:sand")
                api.register_output("default:gravel", "default:sand", 1)
            end)

            -- it("does allow a previously registered output to be registered again if allow_override is switched on", function ()
            --     api.register_input("default:gravel", "default:sand")
            --     api.register_output("default:gravel", "default:sand", 0.1, true)
            --     local registered_output = api.get_outputs("default:gravel", "relative")

            --     assert_equal(registered_output, {["default:sand"]=0.1}, "Output should be overridden properly")
            -- end)

            it("does allow a previously registered output to be registered again", function ()
                api.register_input("default:gravel", "default:sand")
                api.override_output("default:gravel", "default:sand", 0.1)
                local registered_output = api.get_outputs("default:gravel", "relative")
                
                assert_equal(registered_output, {["default:sand"]=0.1}, "Output should be overridden properly")
            end)

            it("does not allow an invalid output to be registered", function ()
                expect_error("attempt to register unknown node \"garbage_nonsense\"")

                api.register_input("default:gravel")
                api.register_output("default:gravel", "garbage_nonsense", 1)
            end)

        end)

        describe("remove_output", function ()
            it("removes a single output from an input", function ()
                local output = {
                    ["default:gravel"] = 1,
                    ["default:sand"] = 1,
                    ["default:coal_lump"] = 0.1
                }
                local expected_output = {
                    ["default:gravel"] = 1,
                    ["default:sand"] = 1
                }
                api.register_input("default:gravel", output)

                api.remove_output("default:gravel", "default:coal_lump")

                local registered_output = api.get_outputs("default:gravel", "relative")

                assert_equal(registered_output, expected_output, "Should be removed properly")

            end)

            it("informs you if you try to remove an output from an input that doesn't exist", function ()
                api.remove_output("default:gravel", "default:coal_lump")

                log_called_times(1)
                log_called_with("error", "Cannot remove an output for an input (%s) that does not exist.", "default:gravel")
            end)
        end)

        describe("swap_output", function ()

            it("removes the old output", function ()
                local output = {
                    ["default:gravel"] = 1,
                    ["default:sand"] = 1,
                    ["default:coal_lump"] = 0.1
                }
                api.register_input("default:gravel", output)
                api.swap_output("default:gravel", "default:coal_lump", "default:iron_lump")

                local registered_output = api.get_outputs("default:gravel", "relative")

                assert_equal(registered_output["default:coal_lump"], nil, "Old output should be properly removed")
            end)
            it("adds in the new output with the old value", function ()
                local output = {
                    ["default:gravel"] = 1,
                    ["default:sand"] = 1,
                    ["default:coal_lump"] = 0.1
                }
                api.register_input("default:gravel", output)
                api.swap_output("default:gravel", "default:coal_lump", "default:iron_lump")

                local registered_output = api.get_outputs("default:gravel", "relative")

                assert_equal(registered_output["default:iron_lump"], 0.1, "New output should be properly added")
            end)
        end)


        describe("get_random_output", function ()

            it("returns outputs (roughly) in the expected distributions", function ()

                local runs = 1000000
                local probabilities = {
                    ["default:gravel"]                  = 0.5,
                    ["default:sand"]                    = 0.5,
                    ["default:coal_lump"]               = 1 / 57.63,
                    ["default:iron_lump"]               = 1 / 59.87,
                    ["default:copper_lump"]             = 1 / 146.31,
                    ["default:tin_lump"]                = 1 / 200.69,
                    ["default:gold_lump"]               = 1 / 445.36,
                    ["default:mese_crystal"]            = 1 / 564.89,
                    ["default:diamond"]                 = 1 / 882.17,
                }
                api.register_input("default:gravel", probabilities)
                local normalized_probabilities = api.scale_probabilities_to_fill(probabilities, runs)
                local results = {}
                for i=1,runs,1 do
                    local output = api.get_random_output("default:gravel")
                    results[output] = (results[output] or 0) + 1
                end

                for name,value in pairs(normalized_probabilities) do
                    local diff = value-(results[name] or 0)
                    local relative = math.abs(diff) / value
                    if relative > 0.1 then
                        fail_test("Random distribution not accurate")
                    end
                end
            end)
        end)
    end)
end)

test.execute()