local l = require "luci.cloud.uci"
local e = require("luci.torchlight.error")
local n = require "luci.cloud.settings"
local r = require("luci.torchlight.setting")
module("luci.controller.admin.cloud_sysupgrade", package.seeall)
function index()
    entry({ "pc", "CloudSysUpgrade.htm" }, template("admin/CloudSysUpgrade")).leaf = true
    entry({ "admin", "cloud" }, call("cloud_image_upgrade")).index = true
    entry({ "admin", "cloud", "cloud_image_upgrade" }, call("cloud_image_upgrade")).leaf = true
    entry({ "admin", "cloud", "cloud_image_load" }, call("cloud_image_load")).leaf = true
end

function image_errcode_transfer(n)
    local l = e.EFWERRNONE
    if -1 == n then
        return e.EEXPT
    elseif 0 == n then
        return e.ENONE
    else
        return (l - n)
    end
end

function get_image_file_name(e)
    local n = l.cursor()
    if e == "upload" then
        name = "/tmp/firmware.img"
    elseif e == "download" then
        local e = n:get_reply_upg_data() or {}
        local e = e[l.OPT_FW_VER_URL] or ""
        name = string.gsub(e, ".+/", "")
        name = string.format("/tmp/%s", name)
    else
        name = nil
    end
    return name
end

function cloud_image_load(t)
    local n = require "luci.sys"
    local c = require "luci.fs"
    local i = require("luci.torchlight.util")
    local n = {}
    local l
    local function o()
        local e = os.execute("/sbin/slpupgrade -c %q > /dev/null 2>&1;echo $? > /tmp/.cloudupgrade_result" % l)
        if 0 == e then
            local n = io.open("/tmp/.cloudupgrade_result", "r")
            e = n:read("*n")
            n:close()
            c.unlink("/tmp/.cloudupgrade_result")
        else
            e = -1
        end
        return e
    end
    local function c() return (luci.sys.exec("md5sum %q" % l):match("^([^%s]+)")) end
    local function c()
        local e = 0
        if nixio.fs.access("/proc/mtd") then
            for n in io.lines("/proc/mtd") do
                local i, l, i, n = n:match('^([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+"([^%s]+)"')
                if n == "linux" or n == "firmware" then
                    e = tonumber(l, 16)
                    break
                end
            end
        elseif nixio.fs.access("/proc/partitions") then
            for n in io.lines("/proc/partitions") do
                local i, i, n, l = n:match('^%s*(%d+)%s+(%d+)%s+([^%s]+)%s+([^%s]+)')
                if n and l and not l:match('[0-9]') then
                    e = tonumber(n) * 1024
                    break
                end
            end
        end
        return e
    end
    content_len = i.get_http_content_len()
    if content_len > r.MAX_UP_FILE_SIZE then
        n[e.NAME] = e.EFILETOOBIG
        luci.http.write_json(n)
        luci.http.setfilehandler(function(e, e, e) end)
        luci.http.formvalue("filename")
        return
    end
    local i
    luci.http.setfilehandler(function(n, e, t)
        if not i then
            if n and n.name == "fileName" then
                i = io.open(l, "w")
            end
        end
        if e then
            i:write(e)
        end
        if t then
            i:close()
        end
    end)
    l = get_image_file_name(t)
    if l == nil then
        n[e.NAME] = e.EFWEXCEPTION
        luci.http.prepare_content("application/json")
        luci.http.write_json(n)
        return
    end
    if t == "upload" then
        luci.http.formvalue("filename")
    end
    n[e.NAME] = image_errcode_transfer(o())
    if e.ENONE ~= n[e.NAME] then
        nixio.fs.unlink(l)
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(n)
end

function cloud_image_upgrade(l)
    local i = require "luci.fs"
    local n = {}
    local l = get_image_file_name(l)
    if l == nil then
        n[e.NAME] = e.EFWEXCEPTION
    else
        n[e.NAME] = e.ENONE
    end
    if not i.isfile(l) then
        n[e.NAME] = e.EFWEXCEPTION
    end
    luci.http.write_json(n)
    if n[e.NAME] == e.ENONE then
        fork_exec("fw forbid; sleep 1; /sbin/slpupgrade %q" % { l })
    end
end

function fork_exec(n)
    local e = nixio.fork()
    if e > 0 then
        return
    elseif e == 0 then
        nixio.chdir("/")
        local e = nixio.open("/dev/null", "w+")
        if e then
            nixio.dup(e, nixio.stderr)
            nixio.dup(e, nixio.stdout)
            nixio.dup(e, nixio.stdin)
            if e:fileno() > 2 then
                e:close()
            end
        end
        nixio.exec("/bin/sh", "-c", n)
    end
end
