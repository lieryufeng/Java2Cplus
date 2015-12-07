#!/usr/bin/perl;

package FileTag;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( isTagValid, getTagString );
use strict;

################################ tag define################################
# common
our $define_idx = -1;
our $DC_START = $define_idx++;
our $DC_unknown = $DC_START;
our $DC_empty = $define_idx++;
our $DC_package = $define_idx++;
our $DC_import = $define_idx++;
our $DC_astart = $define_idx++;
# note
our $DC_note = $define_idx++;
# class
our $DC_class = $define_idx++;
# interface
our $DC_interface = $define_idx++;
# function
our $DC_function_define = $define_idx++;
our $DC_function_call = $define_idx++;
# logic expression
our $DC_logic_unknow = $define_idx++;
our $DC_logic_if = $define_idx++;
our $DC_logic_elseif = $define_idx++;
our $DC_logic_else = $define_idx++;
our $DC_logic_switch = $define_idx++;
our $DC_logic_while = $define_idx++;
our $DC_logic_for = $define_idx++;
our $DC_logic_try = $define_idx++;
our $DC_logic_catch = $define_idx++;
our $DC_logic_finally = $define_idx++;
# varible
our $DC_var_define = $define_idx++;
our $DC_var_assignment = $define_idx++;
# middle by polish
our $DC_scope = $define_idx++;
our $DC_namespace_start = $define_idx++;
our $DC_namespace_end = $define_idx++;
our $DC_macro_start = $define_idx++;
our $DC_macro_end = $define_idx++;
our $DC_class_note = $define_idx++;
our $DC_include = $define_idx++;
our $DC_using_namespace = $define_idx++;

# used for func inner content
our $DC_return = $define_idx++;
our $DC_var_call_var = $define_idx++;

# used for analysis car
our $DC_midbrackets_note = $define_idx++;
our $DC_interface_quote = $define_idx++;
our $DC_namespace = $define_idx++;
our $DC_using_namespace = $define_idx++;
our $DC_module = $define_idx++;
our $DC_typedef = $define_idx++;


our $DC_END = $define_idx++;



################################ tag string hash define################################
# varible string and tag info
our %DC_Idx2Str;

# tag define
# common
$DC_Idx2Str{$DC_unknown} = "DC_unknown";
$DC_Idx2Str{$DC_empty} = "DC_empty";
$DC_Idx2Str{$DC_package} = "DC_package";
$DC_Idx2Str{$DC_import} = "DC_import";
$DC_Idx2Str{$DC_astart} = "DC_astart";
# note
$DC_Idx2Str{$DC_note} = "DC_note";
# class
$DC_Idx2Str{$DC_class} = "DC_class";
# interface
$DC_Idx2Str{$DC_interface} = "DC_interface";
# function
$DC_Idx2Str{$DC_function_define} = "DC_function_define";
$DC_Idx2Str{$DC_function_call} = "DC_function_call";
# logic expression
$DC_Idx2Str{$DC_logic_unknow} = "DC_logic_unknow";
$DC_Idx2Str{$DC_logic_if} = "DC_logic_if";
$DC_Idx2Str{$DC_logic_elseif} = "DC_logic_elseif";
$DC_Idx2Str{$DC_logic_else} = "DC_logic_else";
$DC_Idx2Str{$DC_logic_switch} = "DC_logic_switch";
$DC_Idx2Str{$DC_logic_while} = "DC_logic_while";
$DC_Idx2Str{$DC_logic_for} = "DC_logic_for";
$DC_Idx2Str{$DC_logic_try} = "DC_logic_try";
$DC_Idx2Str{$DC_logic_catch} = "DC_logic_catch";
$DC_Idx2Str{$DC_logic_finally} = "DC_logic_finally";
# varible
$DC_Idx2Str{$DC_var_define} = "DC_var_define";
$DC_Idx2Str{$DC_var_assignment} = "DC_var_assignment";
# middle by polish
$DC_Idx2Str{$DC_scope} = "DC_scope";
$DC_Idx2Str{$DC_namespace_start} = "DC_namespace_start";
$DC_Idx2Str{$DC_namespace_end} = "DC_namespace_end";
$DC_Idx2Str{$DC_macro_start} = "DC_macro_start";
$DC_Idx2Str{$DC_macro_end} = "DC_macro_end";
$DC_Idx2Str{$DC_class_note} = "DC_class_note";
$DC_Idx2Str{$DC_include} = "DC_include";
$DC_Idx2Str{$DC_using_namespace} = "DC_using_namespace";

# used for func inner content
$DC_Idx2Str{$DC_return} = "DC_return";
$DC_Idx2Str{$DC_var_call_var} = "DC_var_call_var";

# used for car
$DC_Idx2Str{$DC_midbrackets_note} = "DC_midbrackets_note";
$DC_Idx2Str{$DC_interface_quote} = "DC_interface_quote";
$DC_Idx2Str{$DC_namespace} = "DC_namespace";
$DC_Idx2Str{$DC_using_namespace} = "DC_using_namespace";
$DC_Idx2Str{$DC_module} = "DC_module";
$DC_Idx2Str{$DC_typedef} = "DC_typedef";



################################ file struct tag define################################
# common
our $K_NodeType = "NODE_TYPE";
our $K_NodeTag = "NODE_TAG";
our $K_NodeName = "NODE_NAME";
our $K_SelfData = "SELF_DATA";
our $K_SelfDataTransed = "SELF_DATA_TRANSED";	# func content, SelfData is before transed
our $K_ParNode = "PAR_LAYER";
our $K_SubNodes = "SUB_LAYERS";
our $K_UsingNamespace = "USING_NAMESPACE";

our $K_Scope = "SCOPE";
our $K_SrcHasScope = "SRC_HAS_SCOPE";

# class | interface
our $K_Parents = "PARENTS";
our $K_Abstract = "CLASS_ABSTRACT";

# func define
our $K_Return = "FUNC_RETURN";
our $K_Params = "FUNC_PARAMS";
our $K_Static = "FUNC_STATIC";
our $K_Final = "FUNC_FINAL";
our $K_Native = "FUNC_NATIVE";
our $K_Virtual = "FUNC_VIRTUAL";
our $K_PureVirtual = "FUNC_PURE_VIRTUAL";
our $K_Synchronized = "FUNC_SYNCHRONIZED";
our $K_InnerContext = "FUNC_INNER_CONTEXT"; # between "{" and "}"
our $K_InnerContextTransed = "FUNC_INNER_CONTEXT_TRANSED"; # between "{" and "}"
our $K_ParamType = "FUNC_PARAM_TYPE";
our $K_ParamName = "FUNC_PARAM_NAME";
our $K_InitList = "FUNC_CONSTRUCT_INIT_LIST";	# polish used but not java need

# func call
our $K_Caller = "FUNC_CALLER";
our $K_Callee = "FUNC_CALLEE";

# var
our $K_VarType = "VAR_TYPE";
our $K_VarName = "VAR_NAME";
our $K_VarAssL = "VAR_ASSIGNMENT_LEFT";
our $K_VarAssR = "VAR_ASSIGNMENT_RIGHT";

# var assign right
our $K_VarAsiRType = "VAR_ASSIGNMENT_RIGHT_TYPE";
our $K_VarAsiRHasNew = "VAR_ASSIGNMENT_RIGHT_HAS_NEW";
our $K_VarAsiRTargetType = "VAR_ASSIGNMENT_RIGHT_TARGET_TYPE";

# func inner class
our $K_InnClassSeq = "INNER_CLASS_SEQ";

# used for car
our $K_ParamInOutType = "FUNC_PARAM_IN_OUT_TYPE";
our $K_Namespace = "NAMESPACE";
our $K_IsCarFunc = "IS_CAR_FUNC";

sub isTagValid
{
	my $tag = shift;
	if ($DC_START < $tag && $tag <= $DC_END) {
		return 1;
	}
	return 0;
}

# input: $tag
# return: string of tag
sub getTagString
{
    my $lineTag = shift;
	my $ret = -7;
	if (exists ($DC_Idx2Str{"$lineTag"})) {
		$ret = $DC_Idx2Str{"$lineTag"};
	}
	else {
		print __LINE__.": lineTag is not in DCINFO, input lineTag=[$lineTag]*********************\n";
	}
    return $ret;
}


1;
