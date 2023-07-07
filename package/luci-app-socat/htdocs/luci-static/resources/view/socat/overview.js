'use strict';
'require view';
'require ui';
'require form';
'require rpc';
'require uci'
'require tools.widgets as widgets';

let newSettingConf = [
    [form.Flag, 'enable', _('enable'), _('active this setting'), {datatype: 'string', rmempty: false, default: '1'}], // enable
    [form.Value, 'remarks', _('remarks'), _('description of this setting'), {datatype: 'string', rmempty: false, default: ''}], // remarks
    [form.ListValue, 'service_type', _('service_type'), _('type specifies the usage of this setting, current only support port forwarding.<br /> By default, this value is port "forwarding".'), {values: ['port_forwarding']}], // type
    [form.ListValue, 'src_proto', _('src protocal'), _('ip family and protocal of source(wan) request'), {values: [['TCP', 'TCP'], ['TCP4', 'TCP4'], ['TCP6', 'TCP6'], ['UDP', 'UDP'], ['UDP4', 'UDP4'], ['UDP6', 'UDP6']], default: 'TCP', rmempty: false}], // src_proto
    [form.Value, 'src_port', _('src port'), _('port of source(wan) request'), {datatype: 'port'}], // protocal
    [form.Flag, 'reuseaddr', _('reuseaddr'), _('whether use local port'), {datatype: 'string', rmempty: false, default: '1'}], // reuseaddr
    [form.ListValue, 'dest_proto', _('dest protocal'), _('local(lan) ip family and protocal of the forward request.'), {values: [['TCP', 'TCP'], ['TCP4', 'TCP4'], ['TCP6', 'TCP6'], ['UDP', 'UDP'], ['UDP4', 'UDP4'], ['UDP6', 'UDP6']], default: 'TCP', rmempty: false}], // dest_protocal
    [form.Value, 'dest_ip', _('dest ip'), _('local(lan) address of the local service.'), {datatype: 'ipaddr', values: []}], // dest_ipv6
    [form.Value, 'dest_port', _('dest port'), _('port of the local service'), {datatype: 'port'}], // dest_port
    [form.Flag, 'firewall_accept', _('firewall accept'), _('whether allow firewall pass'), {datatype: 'string', rmempty: false, default: '1'}]  // firewall_accept
];

// create rpc function to get services status
let callServiceList = rpc.declare({
    object: 'service',
    method: 'list',
    params: ['name'],
    expect: { '': {} }
});

// get instance status
function getInstanceStatus(section_name) {
    return L.resolveDefault(callServiceList('socat'), {}).then(function (res) {
        let isRunning = false;
        try {
            isRunning =res['socat']['instances']['socat.'+ section_name]['running'];
        } catch (e) {}
        return isRunning;  
    })
}

// create instance status node
function renderInstanceStatus(isRunning) {
    let renderHTML = "";
    let spanTemp = '<em><span style="color:%s"><strong>%s</strong></span></em>';

    if (isRunning) {
        renderHTML += String.format(spanTemp, 'green', '✓');
    } else {
        renderHTML += String.format(spanTemp, 'red', 'X');
    }

    return renderHTML;
}

// get service status
function getServiceStatus(section_name) {
    return L.resolveDefault(callServiceList('socat'), {}).then(function (res) {
        let isRunning = {};
        try {
            isRunning = res['socat'];
        } catch (e) {}
        if (isRunning) {
            return true;
        } else {
            return false;
        }
    })
}

// create instance status node
function renderServiceStatus(isRunning) {
    let renderHTML = "";
    let spanTemp = '<em><span style="color:%s"><strong>%s %s</strong></span></em>';

    if (isRunning) {
        renderHTML += String.format(spanTemp, 'green', _('socat'), _('RUNNING'));
    } else {
        renderHTML += String.format(spanTemp, 'red', _('socat'), _('NOT RUNNING'));
    }

    return renderHTML;
}

// create rpc function to get hosts info
let callHostHints = rpc.declare({
    object: 'luci-rpc',
    method: 'getHostHints',
    expect: { '': {} }
});

// tool to create uuid 
function uuid() {
    let s = [];
    let hexDigits = "0123456789abcdef";
    for (let i = 0; i < 32; i++) {
    s[i] = hexDigits.substr(Math.floor(Math.random() * 0x10), 1);
    }
    s[14] = "4"; // bits 12-15 of the time_hi_and_version field to 0010
    s[19] = hexDigits.substr((s[19] & 0x3) | 0x8, 1); // bits 6-7 of the clock_seq_hi_and_reserved to 01
    s[8] = s[13] = s[18] = s[23];
    let uuid = s.join("");
    return uuid;
}


// set params for options in modal tab page 
function setParams(o, params) {
    if (!params) return;
    for (let key in params) {
        let val = params[key];
        if (key === 'values') {
            for (let j = 0; j < val.length; j++) {
                let args = val[j];
                if (!Array.isArray(args))
                    args = [args];
                o.value.apply(o, args);
            }
        } else if (key === 'depends') {
            if (!Array.isArray(val)) {
                val = [val];
            }
            let deps = [];
            for (let j = 0; j < val.length; j++) {
                let d = {};
                for (let vkey in val[j])
                     d[vkey] = val[j][vkey];
                for (let k = 0; k < o.deps.length; k++) {
                    for (let dkey in o.deps[k]) {
                        d[dkey] = o.deps[k][dkey];
                    }
                }
                deps.push(d);
            }
            o.deps = deps;
        } else {
            o[key] = params[key];
        }
    }
    if (params['datatype'] === 'bool') {
        o.enabled = 'true';
        o.disabled = 'false';
    }
}

// create tab in modal page
function defTabOpts(s, t, opts, params) {
    for (let i = 0; i < opts.length; i++) {
        let opt = opts[i];
        let o = s.taboption(t, opt[0], opt[1], opt[2], opt[3]);
        setParams(o, opt[4]);
        setParams(o, params);
    }
}

// when using anonymous, config saved with no section name  
// extend gridsection and override handleAdd function
// add config with uuid section name
// ref https://openwrt.github.io/luci/jsapi/form.js.html#line3355
let cbiUuidGridSection = form.GridSection.extend({
    handleAdd: function(ev, name) {
        let config_name = this.uciconfig || this.map.config,
            // pass uuid as section name
            section_id = this.map.data.add(config_name, this.sectiontype, uuid()),
            mapNode = this.getPreviousModalMap(),
            prevMap = mapNode ? dom.findClassInstance(mapNode) : this.map;

        prevMap.addedSection = section_id;

        return this.renderMoreOptionsModal(section_id);
    }

})

// create views
return view.extend({

    load: function() {
        return Promise.all([
            callHostHints()
        ]);
    },

    render: function(data) {
        
        let hosts = data[0];
        
        let m, s, o;

        m = new form.Map('socat', _('socat'), _("Socat is a versatile networking tool named after 'Socket CAT', which can be regarded as an N-fold enhanced version of NetCat"));

        /////////////////////////////
        // service status show     //
        /////////////////////////////
        s = m.section(form.NamedSection, "_status");
        s.anonymous = false;
        s.addremove = false;

        s.render = function () {
            L.Poll.add(function () {
                return L.resolveDefault(getServiceStatus()).then(function(res) {
                    let view = document.getElementById('service_status');
                    view.innerHTML = renderServiceStatus(res);
                });
            });

            return E('div', { class: 'cbi-map' },
                    E('fieldset', { class: 'cbi-section'}, [
                        E('p', { id: 'service_status' },
                            _('Collection data ...'))
                    ])
            );
        }


        /////////////////////////////
        // service control section //
        /////////////////////////////
        s = m.section(form.NamedSection, "global", "global");
        s.anonymous = true;
        s.addremove = false;

        o = s.option(form.Flag, 'enable', _('Enable'));
        o.rmempty = false;
        o.modalonly = false;
        o.editable = true;
        

        //////////////////////////////////
        // setting show in GridSection //
        //////////////////////////////////
        // s = m.section(form.GridSection, 'instance', _('Port Forward Settings'))
        s = m.section(cbiUuidGridSection, 'instance', _('Port Forward Settings'));
        s.anonymous = true;
        s.addremove = true;
        s.sortable = true;
        s.rowcolors = true;
        s.addbtntitle = _('Add new Settings');
        s.filter = function (s) { return s !== 'example' };

        o = s.option(form.Flag, 'enable', _('enabled'));
        o.modalonly = false;
        o.rmempty = false;
        o.editable = true;
        o = s.option(form.Value, 'status', _('status'));
        o.modalonly = false;
        // if change render function , editable must set to true
        o.editable = true;
        o.render = function (section_id, section_name) {
            // add loop to detect service status and change color and text
            L.Poll.add(function() {
                return L.resolveDefault(getInstanceStatus(section_name)).then(function (res) {
                    let view = document.getElementById('socat.' + section_name);
                    view.innerHTML = renderInstanceStatus(res);
                })
            })

            // add element in page and use loop to change color and text
            return  E('td', 
                        { 
                            'id': 'socat.' + section_name,
                            'class': 'td cbi-value-field',
                            'data-title': 'status',
                            'data-name': 'status',
                            'data-widget': 'CBI.Value'
                        }
                    );
        }
        o = s.option(form.Value, 'src_proto', _('src protocal'));
        o.modalonly = false;
        o.rmempty = false;
        o = s.option(form.Value, 'src_port', _('src port'));
        o.modalonly = false;
        o.rmempty = false;
        o = s.option(form.Value, 'dest_proto', _('dest protocal'));
        o.modalonly = false;
        o.rmempty = false;
        o = s.option(form.Value, 'dest_ip', _('dest ip'));
        o.modalonly = false;
        o.rmempty = false;
        o = s.option(form.Value, 'dest_port', _('dest port'));
        o.modalonly = false;
        o.rmempty = false;
        o = s.option(form.Flag, 'reuseaddr', _('reuseaddr'));
        o.modalonly = false;
        o.editable = true;
        o.rmempty = false;
        o = s.option(form.Flag, 'firewall_accept', _('firewall_accept'));
        o.modalonly = false;
        o.editable = true;
        o.rmempty = false;
        o = s.option(form.Value, 'remarks', _('remarks'));
        o.modalonly = false;
        o.rmempty = false;


        //////////////////////////
        // add new config modal //
        //////////////////////////
        
        // set hosts for selection
        L.sortedKeys(hosts).forEach(function (mac) {
            let l = [];
            let ip = L.toArray(hosts[mac].ipaddrs || hosts[mac].ipv4)[0] ||
                L.toArray(hosts[mac].ip6addrs || hosts[mac].ipv6)[0] || '?';
            let ele = E([], [ mac, ' (', E('strong', [ hosts[mac].name || ip ]), ')' ]);
            newSettingConf[7][4].values.push([ ip, ele ]);
        })

        s.tab('new_setting', _('New Settings'));
        defTabOpts(s, 'new_setting', newSettingConf, {modalonly: true});

        return m.render();
    }

    //,handleSave: function () { }

})