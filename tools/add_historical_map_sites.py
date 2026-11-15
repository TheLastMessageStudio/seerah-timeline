import json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
D=R/'assets/data'
def load(p): return json.loads(p.read_text(encoding='utf-8'))
def save(p,x): p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
places=load(D/'places.json')
new=[
 {'id':'dar_al_arqam','lat':21.4230,'lon':39.8265,'free':True,'description':'Site traditionnellement associé à la maison d’al-Arqam, où les premiers musulmans se réunissaient. L’emplacement exact et les vestiges visibles aujourd’hui ne doivent pas être présentés comme une identification archéologique certaine.','mapPrecision':'approximate'},
 {'id':'safa_marwa','lat':21.4227,'lon':39.8261,'free':True,'description':'Les monticules d’al-Safâ et d’al-Marwa, dans l’enceinte de la Mosquée sacrée. Le repère cartographique désigne la zone rituelle actuelle, sans reconstituer l’aspect du site au VIIe siècle.','mapPrecision':'modern_area'},
 {'id':'masjid_nabawi','lat':24.4672,'lon':39.6113,'free':True,'description':'Emplacement de la Mosquée du Prophète à Madinah. Le bâtiment actuel a connu de nombreux agrandissements ; le point ne représente pas les dimensions de la première mosquée.','mapPrecision':'modern_area'},
 {'id':'khandaq','lat':24.4820,'lon':39.5790,'free':True,'description':'Zone traditionnellement associée au fossé défensif au nord de Madinah. Le tracé exact du fossé historique n’est pas restitué par ce point indicatif.','mapPrecision':'approximate'},
 {'id':'tabuk','lat':28.3838,'lon':36.5662,'free':True,'description':'Ville de Tabuk, repère régional de l’expédition traditionnellement située en 9 AH. Le point désigne la ville actuelle, non un campement précisément identifié.','mapPrecision':'regional'},
 {'id':'muzdalifah','lat':21.3895,'lon':39.9110,'free':True,'description':'Zone de Muzdalifah entre ʿArafât et Minâ, étape des rites du pèlerinage. Le repère désigne la zone actuelle et non un emplacement précis de campement au VIIe siècle.','mapPrecision':'modern_area'},
]
existing={p['id'] for p in places}
for p in new:
 if p['id'] not in existing: places.append(p)
save(D/'places.json',places)
# Link events to the sites discussed by their existing narratives.
events=load(D/'events.json')
links={
 'secret_preaching':['dar_al_arqam'], 'dar_arqam':['dar_al_arqam'], 'first_believers':['dar_al_arqam'], 'safa_call':['safa_marwa'],
 'masjid_nabawi':['masjid_nabawi'], 'arrive_madinah':['masjid_nabawi'], 'khandaq':['khandaq'],
 'tabuk':['tabuk'], 'farewell_hajj':['muzdalifah'],
}
for e in events:
 for pid in links.get(e['id'],[]):
  if pid not in e.get('placeIds',[]): e.setdefault('placeIds',[]).append(pid)
save(D/'events.json',events)
translations={
 'fr':{
  'dar_al_arqam':('Dâr al-Arqam','دار الأرقم','Maison traditionnellement associée aux réunions des premiers musulmans à Makkah. Son emplacement exact demeure indicatif.'),
  'safa_marwa':('Al-Safâ et al-Marwa','الصفا والمروة','Zone des deux monticules situés dans l’enceinte de la Mosquée sacrée, repère du saʿy lors du pèlerinage.'),
  'masjid_nabawi':('Mosquée du Prophète','المسجد النبوي','Emplacement de la mosquée fondée à Madinah ; l’édifice actuel est le résultat de nombreux agrandissements.'),
  'khandaq':('Zone du Fossé','موضع الخندق','Secteur traditionnellement associé au fossé défensif de Madinah. Le tracé exact est approximatif.'),
  'tabuk':('Tabuk','تبوك','Ville du nord-ouest de l’Arabie, repère régional de l’expédition de Tabuk.'),
  'muzdalifah':('Muzdalifah','مزدلفة','Zone rituelle située entre ʿArafât et Minâ dans le parcours du pèlerinage.'),
 },
 'en':{
  'dar_al_arqam':('Dar al-Arqam','دار الأرقم','House traditionally associated with the gatherings of the first Muslims in Makkah. Its exact location remains indicative.'),
  'safa_marwa':('Al-Safa and al-Marwa','الصفا والمروة','Area of the two hills within the Sacred Mosque, a landmark for the saʿy during pilgrimage.'),
  'masjid_nabawi':('Prophet’s Mosque','المسجد النبوي','Site of the mosque established in Madinah; the present building reflects many later expansions.'),
  'khandaq':('Trench area','موضع الخندق','Area traditionally associated with the defensive trench at Madinah. The exact historical line is approximate.'),
  'tabuk':('Tabuk','تبوك','City in north-west Arabia and regional reference point for the Tabuk expedition.'),
  'muzdalifah':('Muzdalifah','مزدلفة','Ritual area between ʿArafat and Mina on the pilgrimage route.'),
 },
 'ar':{
  'dar_al_arqam':('دار الأرقم','دار الأرقم','دار تُنسب إليها اجتماعات المسلمين الأوائل في مكة. ويظل تحديد موضعها الدقيق تقريبياً.'),
  'safa_marwa':('الصفا والمروة','الصفا والمروة','منطقة الجبلين داخل المسجد الحرام، وهي موضع السعي في الحج والعمرة.'),
  'masjid_nabawi':('المسجد النبوي','المسجد النبوي','موضع المسجد الذي أُسس في المدينة؛ أما البناء الحالي فقد مر بتوسعات عديدة.'),
  'khandaq':('موضع الخندق','موضع الخندق','منطقة تُربط تقليدياً بالخندق الدفاعي حول المدينة. ويظل مساره التاريخي الدقيق تقريبياً.'),
  'tabuk':('تبوك','تبوك','مدينة في شمال غرب الجزيرة العربية، وهي علامة جغرافية إقليمية لغزوة تبوك.'),
  'muzdalifah':('مزدلفة','مزدلفة','منطقة من مناسك الحج تقع بين عرفات ومنى.'),
 }}
for lang, items in translations.items():
 path=D/f'i18n/{lang}/places.json'; data=load(path)
 for pid,(name,namear,desc) in items.items(): data[pid]={'name':name,'nameAr':namear,'description':desc}
 save(path,data)
print('Added 6 mapped sites and linked 8 event cards.')
