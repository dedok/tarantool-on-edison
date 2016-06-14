var Sensor = React.createClass({
    getInitialState: function() {
        return {
            value: this.props.value,
            name: this.props.name,
            label: "success",
            lb_class: "pull-right label label-",
            sensor_name: this.props.sensor_name + this.props.sensor_name,
            measure: this.props.measure,
            max: this.props.max,
            alert: this.props.alert,
            device_name: "",
            chart: {}
        };
    },
    componentDidMount: function() {
        this.props.append(this.props.name, "success");
        this.state.chart = new Highcharts.Chart({
            chart: {
                type: "line",
                renderTo : this.state.sensor_name,
            },
            title: { text: ""},
            yAxis: {
                title: { text: this.state.measure},
                plotLines: [{
                    width: 2,
                    value: this.state.max,
                    color: '#FF0000'
                }]
            },
            plotOptions: {
                line: {
                    dataLabels: { enabled: false},
                    enableMouseTracking: false,
                    marker: {
                        enabled: false
                    }
                }
            },
            series: [{
                name: 'Показания',
                data: this.props.series
            }]
        });
        setTimeout( this.updateChart, 1000);
    },
    componentWillUnmount: function() {
        this.chart.destroy();
    },
    update_value: function(point) {
        var cls = point > this.state.max ? 'danger' : 'success';
        this.state.chart.series[0].addPoint(point, true, true);
        this.props.append(this.state.name, cls);
        this.setState({value: point, label: cls});
    },
    update_settings: function(event) {
        var eid = $(event.target).attr('action');
        var value = parseInt($('#' + eid).val());
        var uri = this.props.settings;
        uri += '?name=' + this.props.device_name;
        uri += '&sensor=' + this.props.sensor_name;
        uri += '&max=' + value;

        var self = this;
        $.get(uri, function(resp){
            self.setState({max: value});
            self.state.chart.axes[1].plotLinesAndBands[0].options.value = value;
        });
    },
    updateChart: function() {
        var self = this;
        $.get(this.props.detail + this.props.device_name, function(resp){
            var series = self.state.chart.series[0];
            // find sensor in device
            for(var e=0;e<resp.data.length;e++){
                if(resp.data[e].sensor_name != self.props.sensor_name)
                    continue;
                for(var i=0;i<resp.data[e].series.length;i++){
                    self.update_value(resp.data[e].series[i]);
                }
            }
            setTimeout(self.updateChart, 1000);
        });
    },
    render: function() {
        return <div className="col-md-4 sensor">
            <div className='thumbnail'>
                <div className='caption'>
                     <h3>
                       {this.state.name}
                       <span className={this.state.lb_class + this.state.label}>
                           {this.state.value} {this.state.measure}
                       </span>
                     </h3>
                </div>
                <div id={this.state.sensor_name} className="plot"></div>
                <div className='caption'>
                  <div className="input-group">
                    <input
                        type="number"
                        defaultValue={this.state.max}
                        className="form-control"
                        placeholder="Максимальное значение"
                        id={"btn_" + this.state.sensor_name}
                        aria-describedby="basic-addon2"
                    />
                    <span className="input-group-btn">
                        <button 
                            onClick={this.update_settings}
                            className="btn btn-default"
                            action={"btn_" + this.state.sensor_name}
                            type="button"
                        >OK</button>
                    </span>
                  </div>
                </div>
            </div>
         </div>
    }
});

var SensorList = React.createClass({
    componentDidMount: function() {
        this.serverRequest = $.get(this.props.uri, function (result) {
            var list = [];
            var res = result.list
            // devices
            for(var l=0;l<res.length;l++){
                // sensors
                var device_list = res[l];
                for(var i=0;i<device_list.data.length;i++){
                    var sensor = device_list.data[i];
                    sensor.value = sensor.series[sensor.series.length - 1];
                    sensor.device_name = device_list.device_name
                    list.push(sensor);
                }
            }
            this.setState({items:list})
        }.bind(this));
    },
    componentWillUnmount: function() {
        this.serverRequest.abort();
    },
    getInitialState: function() {
        return {items: []}
    },
    render: function() {
        var append_cb = this.props.append;
        var self = this;
        var createSensor = function(opts, index) {
            return <Sensor {...opts}
                       append={append_cb}
                       detail={self.props.detail}
                       settings={self.props.settings}
                       key={index}
                   />;
        }
        return <div>
            {this.state.items.map(createSensor)}
        </div>
    }
});

var SecurityIndicator = React.createClass({
    childs: {},
    UI_OK: "Система в безопасности",
    UI_ER: "Обнаружена угроза",
    getInitialState: function() {
        return {
            cls: "alert alert-",
            status: "success",
            text: this.UI_OK
        };
    },
    append: function(name, obj){
        this.childs[name] = obj
        this.update()
    },
    update: function(){
        var ok = true;
        var cls = 'success';
        var text = this.UI_OK
        var childs = this.childs;
        Object.keys(childs).map(function(key) {
            if(childs[key] == 'danger')
                ok = false;
        });

        if(!ok){
            cls = "danger";
            text = this.UI_ER;
        }
        this.setState({
            status: cls,
            text: text
        });
    },
    render: function() {
        return <div className="UI">
            <div className={this.state.cls + this.state.status} role="alert">
                <p>{this.state.text}</p>
            </div>
            <div id="panel" className="row sensors">
                <SensorList
                    uri={this.props.api_list}
                    append={this.append}
                    detail={this.props.api_detail}
                    settings={this.props.api_post}
                />
            </div>
        </div>
    }
});

ReactDOM.render(
    <SecurityIndicator
        api_list="/api/list"
        api_detail="/api/get?name="
        api_post="/api/set"
    />,
    $('#state')
);
