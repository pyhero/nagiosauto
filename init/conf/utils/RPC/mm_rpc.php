<?php
/**
 * MM
 *
 * MM XML-RPC Client Class. All methods listed below stores result in $result.
 *
 * @package     what??
 * @subpackage  what??
 * @author      huapinghuang@sohu-inc.com
 * @copyright   Copyright (c) 2009, sohu,Inc.
 * @version     0.1
 * @since       Version 0.1
 */

class MM {
    const CONF_FILE = 'mm_conf.php';
	const CONF_ARRAY = 'conf_mm';
    private $_context;
    private $_url;
    private $result;

    /**
     * __construct
     *
     * This is the construct function of MM class, which simply create a stream context for XML-RPC requests
     *
     */
    function __construct() {
	    require_once self::CONF_FILE;
        $this->_context = stream_context_create(array(
                                                      'http' => array(
                                                                      'method' => 'POST',
                                                                      'header' => 'Content-Type: text/xml',
                                                                     )
                                                     )
                                               );
        $this->_url = ${self::CONF_ARRAY}['url'];
    }

    /**
     * __get
     *
     * This is the magic method of getting attributes
     *
     */

    function __get($name) {
        return $this->$name;
    }

    /**
     * _request_rpc
     *
     * This method actually perform XML-RPC requests
     *
     * @access  private
     * @param   string $method query method
     * @param   array $params query params
     * @return  boolean TRUE if succeeded, FALSE if failed
     */

    private function _request_rpc($method, $params = array()) {
        $request = xmlrpc_encode_request($method, $params);
        $context = $this->_context;
        stream_context_set_option($context, 'http', 'content', $request);
        $content = file_get_contents($this->_url, FALSE, $context);
        $response = xmlrpc_decode($content);
        if (xmlrpc_is_fault($response)) {
            trigger_error("xmlrpc: $response[faultString] ($response[faultCode])");
            return FALSE;
        }
        $this->result = $response;
        return TRUE;
    }

    /**
     * system_list_methods
     *
     * This method offers a list of the methods the server has, by name.
     *
     * @access  public
     * @return  boolean TRUE if succeeded, FALSE if failed
     */

    public function system_list_methods() {
        return $this->_request_rpc('system.listMethods');
    }

    /**
     * system_method_signature
     *
     * This method offers a description of the argument format a particular method expects.
     *
     * @access  public
     * @param   string $method_name name of the method to query
     * @return  boolean TRUE if succeeded, FALSE if failed
     */

    public function system_method_signature($method_name) {
        return $this->_request_rpc('system.methodSignature', array($method_name));
    }

    /**
     * system_method_help
     *
     * This method offers a text description of a particular method.
     *
     * @access  public
     * @param   string $method_name name of the method to query
     * @return  boolean TRUE if succeeded, FALSE if failed
     */

    public function system_method_help($method_name) {
        return $this->_request_rpc('system.methodHelp', array($method_name));
    }

    /**
     * host_get_info
     *
     * This method offers information of the host owning the specified IP(s).
     * 
     * @access  public
     * @param   mixed array|string $ip IP address(es) to query
     * @param   boolean $purge Whether to purge cache
     * @return  boolean TRUE if succeeded, FALSE if failed
     */

    public function host_get_info($ip, $purge = FALSE) {
        return $this->_request_rpc('host.getInfo', array($ip, $purge));
    }

    /**
     * host_get_ip_info
     *
     * This method offers information of the interface owning the specified IP(s).
     * 
     * @access  public
     * @param   mixed array|string $ip IP address(es) to query
     * @param   boolean $purge Whether to purge cache
     * @return  boolean TRUE if succeeded, FALSE if failed
     */

    public function host_get_ip_info($ip, $purge = FALSE) {
        return $this->_request_rpc('host.getIPInfo', array($ip, $purge));
    }

    /**
     * host_get_traffic
     *
     * This method offers traffic data of the interface owning the specified IP(s).
     * 
     * @access  public
     * @param   mixed array|string $ip IP address(es) to query
     * @param   int $time timestamp of the moment to query
     * @return  boolean TRUE if succeeded, FALSE if failed
     */

    public function host_get_traffic($ip, $time = -1) {
        return $this->_request_rpc('host.getTraffic', array($ip, $time));
    }

    /**
     * host_get_traffic_graph
     *
     * This method offers traffic graph URL of the interface owning the specified IP(s).
     * 
     * @access  public
     * @param   mixed array|string $ip IP address(es) to query
     * @param   int $start Start timestamp of the timerange to query
     * @param   int $end End timestamp of the timerange to query
     * @return  boolean TRUE if succeeded, FALSE if failed
     */

    public function host_get_traffic_graph($ip, $start = -1, $end = -1) {
        return $this->_request_rpc('host.getTrafficGraph', array($ip, $start, $end));
    }

    /**
     * squid_get_data
     *
     * This method offers squid statistics data of the corresponding IP(s).
     * 
     * @access  public
     * @param   mixed array|string $ip IP address(es) to query
     * @param   int $time timestamp of the moment to query
     * @return  boolean TRUE if succeeded, FALSE if failed
     */

    public function squid_get_data($ip, $time = -1) {
        return $this->_request_rpc('squid.getData', array($ip, $time));
    }

    /**
     * squid_get_graph
     *
     * This method offers squid statistics graph URLs of the corresponding IP(s).
     * 
     * @access  public
     * @param   mixed array|string $ip IP address(es) to query
     * @param   int $start Start timestamp of the timerange to query
     * @param   int $end End timestamp of the timerange to query
     * @return  boolean TRUE if succeeded, FALSE if failed
     */

    public function squid_get_graph($ip, $start = -1, $end = -1) {
        return $this->_request_rpc('squid.getGraph', array($ip, $start, $end));
    }

    /**
     * squid_get_grp_data
     *
     * This method offers cache group statistics data of the corresponding domain(s).
     * 
     * @access  public
     * @param   mixed array|string $domain Domain name(s) to query
     * @param   int $time timestamp of the moment to query
     * @return  boolean TRUE if succeeded, FALSE if failed
     */

    public function squid_get_grp_data($domain, $time = -1) {
        return $this->_request_rpc('squid.getGrpData', array($domain, $time));
    }

    /**
     * squid_get_grp_graph
     *
     * This method offers cache group statistics graph URLs of the corresponding domain(s).
     * 
     * @access  public
     * @param   mixed array|string $domain Domain name(s) to query
     * @param   int $start Start timestamp of the timerange to query
     * @param   int $end End timestamp of the timerange to query
     * @return  boolean TRUE if succeeded, FALSE if failed
     */

    public function squid_get_grp_graph($domain, $start = -1, $end = -1) {
        return $this->_request_rpc('squid.getGrpGraph', array($domain, $start, $end));
    }

    /**
     * squid_get_info
     * 
     * This method offers squid information of the corresponding IP(s).
     * 
     * @access  public
     * @param   mixed array|string $ip IP address(es) to query
     * @param   boolean $purge Whether to purge cache
     * @return  boolean TRUE if succeeded, FALSE if failed
     */

    public function squid_get_info($ip, $purge = FALSE) {
        return $this->_request_rpc('squid.getInfo', array($ip, $purge));
    }
}

/* end of mm_rpc.php */
