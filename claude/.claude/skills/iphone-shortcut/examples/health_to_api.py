"""Build 'Sleep to intervals' .shortcut (unsigned plist XML). Usage: python3 -I build_shortcut.py OUT.shortcut"""
import plistlib, sys, uuid, os, pathlib
U = lambda: str(uuid.uuid4()).upper()
OBJ = '￼'

def out(uid, name):            # reference to an action's output
    return {'OutputUUID': uid, 'OutputName': name, 'Type': 'ActionOutput'}
def var(name):                 # named variable (e.g. Repeat Item)
    return {'Type': 'Variable', 'VariableName': name}
def prop(ref, p, iso=False):   # property of a variable, optionally formatted as ISO 8601
    a = [{'Type': 'WFPropertyVariableAggrandizement', 'PropertyName': p}]
    if iso: a.append({'Type': 'WFDateFormatVariableAggrandizement', 'WFDateFormatStyle': 'ISO 8601', 'WFISO8601IncludeTime': True})
    return dict(ref, Aggrandizements=a)
def att(ref):                  # a single variable as a parameter
    return {'Value': ref, 'WFSerializationType': 'WFTextTokenAttachment'}
def tok(*parts):               # text mixing literal strings and variable refs
    s, ranges = '', {}
    for p in parts:
        if isinstance(p, str): s += p
        else: ranges['{%d, 1}' % (len(s.encode('utf-16-le')) // 2)] = p; s += OBJ
    v = {'string': s}
    if ranges: v['attachmentsByRange'] = ranges
    return {'Value': v, 'WFSerializationType': 'WFTextTokenString'}
def act(ident, **params):
    return {'WFWorkflowActionIdentifier': ident, 'WFWorkflowActionParameters': params}
def dict_field(pairs):         # WFDictionaryFieldValue for headers / JSON body
    return {'Value': {'WFDictionaryFieldValueItems': [
        {'WFItemType': 0, 'WFKey': tok(k), 'WFValue': v} for k, v in pairs]},
        'WFSerializationType': 'WFDictionaryFieldValue'}

# Type filter shape and labels per viticci/shortcuts-playground-plugin HEALTHKIT.md (observed iOS exports):
# 'Bounded': True on the Type row; Find Health Samples picker label for sleep is 'Sleep', not 'Sleep Analysis'.
A = []
# Embed the key when EMBED_KEY=1 (Tomer asked 2026-11-22); otherwise ask on import.
EMBED = os.environ.get('EMBED_KEY') == '1'
KEY = (pathlib.Path.home()/'personal/.secrets/intervals_api_key').read_text().strip() if EMBED else 'PASTE_API_KEY'
# v7: ground truth from a real exported shortcut (Matthew Cassinelli's 'Export Heart Rate data', client 3607):
# the locked template is Type row + a NON-removable 'Start Date is in the last N days' row
# (Operator 1001, Values {Number: '7' as string, Unit: 16 = days}). 'Heart Rate' label confirmed.
def find_samples(type_name, limit):
    uid = U()
    A.append(act('is.workflow.actions.filter.health.quantity', UUID=uid,
        WFContentItemFilter={'Value': {'WFActionParameterFilterPrefix': 1, 'WFContentPredicateBoundedDate': False,
            'WFActionParameterFilterTemplates': [{'Bounded': True, 'Operator': 4, 'Property': 'Type', 'Removable': False,
                'Values': {'Enumeration': {'Value': type_name, 'WFSerializationType': 'WFStringSubstitutableState'}}},
               {'Bounded': True, 'Operator': 1001, 'Property': 'Start Date', 'Removable': False,
                'Values': {'Number': '1', 'Unit': 16}}]},
            'WFSerializationType': 'WFContentPredicateTableTemplate'},
        WFContentItemSortProperty='Start Date', WFContentItemSortOrder='Latest First',
        WFContentItemLimitEnabled=True, WFContentItemLimitNumber=limit))
    return uid, 'Health Samples'
def lines_of(src, with_end):
    """Repeat over samples -> 'start;end;value' or 'start;value' lines -> Combine Text. Returns combine UUID."""
    g, end_uid, comb = U(), U(), U()
    A.append(act('is.workflow.actions.repeat.each', GroupingIdentifier=g, WFControlFlowMode=0, WFInput=att(out(*src))))
    ri = var('Repeat Item')
    parts = [prop(ri, 'Start Date', True), ';'] + ([prop(ri, 'End Date', True), ';'] if with_end else []) + [prop(ri, 'Value')]
    A.append(act('is.workflow.actions.gettext', UUID=U(), WFTextActionText=tok(*parts)))
    A.append(act('is.workflow.actions.repeat.each', GroupingIdentifier=g, WFControlFlowMode=2, UUID=end_uid))
    A.append(act('is.workflow.actions.text.combine', UUID=comb, WFTextSeparator='New Lines', text=att(out(end_uid, 'Repeat Results'))))
    return comb

A.append(act('is.workflow.actions.comment', WFCommentActionText=
    'Sends last night\'s Apple Watch sleep stages plus heart rate and HRV samples to intervals.icu (custom fields SleepRaw, HRRaw, HRVRaw) for the sleep-doctor daily report. Run it after waking, or from a daily automation.'))
# v2: no Repeat loops (3000 iterations took minutes). A property of a list variable gives the list of
# that property; inserted into Text it is joined with new lines. Blocks are separated by '---' lines and
# zipped back together on the Mac (scripts/sleepraw.py).
def blocks_of(src, props):
    uid = U(); parts = []
    for i, (p, iso) in enumerate(props):
        if i: parts.append('\n---\n')
        parts.append(prop(out(*src), p, iso))
    A.append(act('is.workflow.actions.gettext', UUID=uid, WFTextActionText=tok(*parts)))
    return uid, 'Text'
sleep_t = blocks_of(find_samples('Sleep', 150), [('Start Date', True), ('End Date', True), ('Value', False)])
hr_t    = blocks_of(find_samples('Heart Rate', 700), [('Start Date', True), ('Value', False)])
hrv_t   = blocks_of(find_samples('Heart Rate Variability', 40), [('Start Date', True), ('Value', False)])

key_uid, ath_uid, auth_uid, b64_uid, date_uid = U(), U(), U(), U(), U()
key_index = len(A); A.append(act('is.workflow.actions.gettext', UUID=key_uid, WFTextActionText=tok(KEY)))
ath_index = len(A); A.append(act('is.workflow.actions.gettext', UUID=ath_uid, WFTextActionText=tok('i000000')))
A.append(act('is.workflow.actions.gettext', UUID=auth_uid, WFTextActionText=tok('API_KEY:', out(key_uid, 'Text'))))
A.append(act('is.workflow.actions.base64encode', UUID=b64_uid, WFEncodeMode='Encode', WFBase64LineBreakMode='None', WFInput=att(out(auth_uid, 'Text'))))
A.append(act('is.workflow.actions.format.date', UUID=date_uid, WFDateFormatStyle='Custom', WFDateFormat='yyyy-MM-dd',
             WFDate=tok({'Type': 'CurrentDate'})))
VER = 'v7'
dl_uid = U()
A.append(act('is.workflow.actions.downloadurl', UUID=dl_uid, ShowHeaders=True, WFHTTPMethod='PUT', WFHTTPBodyType='JSON',
    WFURL=tok('https://intervals.icu/api/v1/athlete/', out(ath_uid, 'Text'), '/wellness/', out(date_uid, 'Formatted Date')),
    WFHTTPHeaders=dict_field([('Authorization', tok('Basic ', out(b64_uid, 'Base64 Encoded')))]),
    WFJSONValues=dict_field([('SleepRaw', tok(out(*sleep_t))),
                             ('HRRaw', tok(out(*hr_t))),
                             ('HRVRaw', tok(out(*hrv_t))),
                             ('SleepSyncVer', tok(VER + ' ', dict({'Type': 'CurrentDate'}, Aggrandizements=[{'Type': 'WFDateFormatVariableAggrandizement', 'WFDateFormatStyle': 'ISO 8601', 'WFISO8601IncludeTime': True}])))])))
# Non-blocking confirmation with the start of the server reply (diagnostics).
A.append(act('is.workflow.actions.notification', WFNotificationActionTitle='Sleep to intervals ' + VER,
             WFNotificationActionSound=False, WFNotificationActionBody=tok('Sent. Server reply: ', out(dl_uid, 'Contents of URL'))))

wf = {
    'WFWorkflowActions': A,
    'WFWorkflowClientVersion': '2607.0.2',
    'WFWorkflowMinimumClientVersion': 900,
    'WFWorkflowMinimumClientVersionString': '900',
    'WFWorkflowIcon': {'WFWorkflowIconStartColor': 463140863, 'WFWorkflowIconGlyphNumber': 59511},
    'WFWorkflowImportQuestions': ([] if EMBED else [
        {'ActionIndex': key_index, 'Category': 'Parameter', 'ParameterKey': 'WFTextActionText', 'DefaultValue': '',
         'Text': 'Your intervals.icu API key (intervals.icu → Settings → Developer Settings)'},
        {'ActionIndex': ath_index, 'Category': 'Parameter', 'ParameterKey': 'WFTextActionText', 'DefaultValue': 'i000000',
         'Text': 'Your intervals.icu athlete ID'}]) if not EMBED else [],
    'WFWorkflowInputContentItemClasses': ['WFAppStoreAppContentItem', 'WFArticleContentItem', 'WFContactContentItem',
        'WFDateContentItem', 'WFEmailAddressContentItem', 'WFGenericFileContentItem', 'WFImageContentItem',
        'WFiTunesProductContentItem', 'WFLocationContentItem', 'WFDCMapsLinkContentItem', 'WFAVAssetContentItem',
        'WFPDFContentItem', 'WFPhoneNumberContentItem', 'WFRichTextContentItem', 'WFSafariWebPageContentItem',
        'WFStringContentItem', 'WFURLContentItem'],
    'WFWorkflowOutputContentItemClasses': [],
    'WFWorkflowTypes': [],
    'WFQuickActionSurfaces': [],
    'WFWorkflowHasShortcutInputVariables': False,
    'WFWorkflowHasOutputFallback': False,
}
with open(sys.argv[1], 'wb') as f: plistlib.dump(wf, f, fmt=plistlib.FMT_XML)
print(len(A), 'actions')
