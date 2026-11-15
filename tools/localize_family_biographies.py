import json
from pathlib import Path
R=Path(__file__).resolve().parents[1]; D=R/'assets/data'
def load(p): return json.loads(p.read_text(encoding='utf-8'))
def save(p,x): p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
# Explicitly translate the short family notices already present in English or as generic Arabic placeholders.
fr={
'fatimah_bint_asad':"Fâtima bint Asad est l’épouse d’Abû Tâlib et la mère d’Ali et de Jaʿfar dans la généalogie familiale retenue ici. Son foyer appartient à la branche des Banû Hâshim qui entoure l’enfance du Prophète ﷺ. La notice la situe comme mère et membre de la famille, sans lui attribuer un récit indépendant absent des fiches actuelles.",
'al_abbas':"Al-ʿAbbâs est l’un des oncles paternels du Prophète ﷺ. La tradition généalogique le présente comme l’ancêtre de la lignée abbasside. Son lien avec la famille de Muhammad ﷺ est représenté dans l’arbre ; les épisodes de sa vie ne sont pas développés dans la chronologie actuelle.",
'safiyyah_bint_abd_al_muttalib':"Safiyya bint ʿAbd al-Muttalib est la tante paternelle du Prophète ﷺ et la mère d’al-Zubayr ibn al-ʿAwwâm selon les notices biographiques. Elle appartient à la famille des Banû Hâshim et apparaît dans l’arbre familial à côté des fils et filles de ʿAbd al-Muttalib.",
'al_harith':"Al-Hârith est l’un des fils de ʿAbd al-Muttalib et donc un oncle paternel du Prophète ﷺ dans la généalogie traditionnelle. Sa notice sert à montrer la composition de la famille proche des Banû Hâshim ; les sources recensées ici ne fournissent pas de récit détaillé de sa vie.",
'qasim':"Al-Qâsim est présenté dans la tradition biographique comme le fils du Prophète ﷺ et de Khadîja. Il meurt en bas âge. Son nom est associé à la kunya Abû al-Qâsim portée par le Prophète ﷺ ; les détails chronologiques de sa courte vie restent peu développés dans les sources de cette application.",
'zaynab_bint_muhammad':"Zaynab est l’une des filles du Prophète ﷺ et de Khadîja selon la tradition familiale. Elle épouse Abû al-ʿÂs ibn al-Rabîʿ et leur fille Umâma apparaît dans l’arbre. Son parcours est relié aux récits des premières années de la communauté et aux liens entre les familles de Makkah.",
'ruqayyah':"Ruqayya est l’une des filles du Prophète ﷺ et de Khadîja. La tradition rapporte qu’elle émigre en Abyssinie avec son époux ʿUthmân ibn ʿAffân. Son histoire relie la famille du Prophète ﷺ aux premières migrations et à la formation de la communauté hors de Makkah.",
'umm_kulthum':"Umm Kulthûm est l’une des filles du Prophète ﷺ et de Khadîja. Les notices biographiques rapportent qu’elle épouse plus tard ʿUthmân ibn ʿAffân, après Ruqayya. Elle est représentée dans l’arbre familial parmi les enfants du Prophète ﷺ ; les détails de sa vie restent moins développés dans la chronologie.",
'fatimah_bint_muhammad':"Fâtima est la fille du Prophète ﷺ et de Khadîja. Elle épouse ʿAlî ibn Abî Tâlib et devient la mère d’al-Hasan et d’al-Husayn. Son lien avec plusieurs générations de la famille est visible dans l’arbre ; elle occupe une place centrale dans la mémoire familiale musulmane.",
'abdullah_ibn_muhammad':"ʿAbd Allâh est présenté dans la tradition biographique comme le fils du Prophète ﷺ et de Khadîja. Il meurt en bas âge. Les récits le mentionnent parmi les enfants du foyer de Makkah, mais les informations détaillées sur sa courte vie sont limitées.",
'umama':"Umâma est la fille de Zaynab bint Muhammad et d’Abû al-ʿÂs ibn al-Rabîʿ selon la généalogie traditionnelle. Elle est donc la petite-fille du Prophète ﷺ. Son nom apparaît dans les notices familiales et l’arbre relie directement sa fiche à celles de ses parents.",
'abu_al_as':"Abû al-ʿÂs ibn al-Rabîʿ est l’époux de Zaynab, fille du Prophète ﷺ, et son gendre. Les récits biographiques le situent dans les relations entre les Banû Hâshim et les familles de Quraysh. L’arbre familial relie sa notice à Zaynab et à leur fille Umâma.",
'sawda':"Sawda bint Zamʿa est l’une des épouses du Prophète ﷺ. La tradition la situe dans le foyer prophétique après le décès de Khadîja. Sa notice rappelle sa place parmi les Mères des croyants ; les événements actuellement répertoriés ne développent pas séparément tous les épisodes de sa vie.",
'hafsa':"Hafsa bint ʿUmar est la fille de ʿUmar ibn al-Khattâb et l’une des épouses du Prophète ﷺ. Elle appartient ainsi à la fois à la famille des Mères des croyants et à la famille du futur deuxième calife. Les détails de sa vie sont à lire avec les notices biographiques et les sources propres à chaque épisode.",
'umm_salama':"Umm Salama, Hind bint Abî Umayya, est l’une des épouses du Prophète ﷺ. La tradition la retient pour sa connaissance et la pertinence de ses conseils. Sa biographie s’inscrit dans l’histoire des premières migrations et de la communauté médinoise ; les récits doivent être attribués à leurs sources respectives.",
'zaynab_bint_jahsh':"Zaynab bint Jahsh est l’une des épouses du Prophète ﷺ. Son mariage est évoqué explicitement dans le Coran, en 33:37, ce qui donne à sa notice un lien direct avec le texte coranique. Les autres détails biographiques doivent être distingués de ce passage précis.",
'juwayriya':"Juwayriya bint al-Hârith est l’une des épouses du Prophète ﷺ et appartient à Banû al-Mustaliq selon la tradition biographique. Son histoire est liée aux récits de cette tribu et aux conséquences de l’expédition. Les détails doivent être lus en tenant compte des variantes des sources de Sîra.",
'safiyya_bint_huyayy':"Safiyya bint Huyayy est l’une des épouses du Prophète ﷺ. Les biographies la présentent comme issue d’une famille juive de Khaybar. Sa notice relie l’histoire familiale aux événements du nord du Hijaz ; les récits de cette période demandent une lecture attentive de leurs différentes transmissions.",
'umm_habiba':"Umm Habîba, Ramla bint Abî Sufyân, est la fille d’Abû Sufyân. La tradition rapporte qu’elle émigre en Abyssinie avant son mariage avec le Prophète ﷺ. Son parcours relie les premières migrations, les relations entre familles de Quraysh et la communauté musulmane.",
'maymuna':"Maymûna bint al-Hârith est l’une des épouses du Prophète ﷺ. Les notices biographiques situent son mariage dans la période médinoise tardive. Elle apparaît dans l’arbre familial parmi les Mères des croyants ; les dates et circonstances détaillées doivent être vérifiées dans les sources biographiques.",
'mariya_al_qibtiyya':"Mâriya al-Qibtiyya est la mère d’Ibrâhîm, fils du Prophète ﷺ selon la tradition biographique. Son nom est ainsi lié à la dernière période de la vie du Prophète ﷺ et à la naissance puis au décès précoce de son fils. L’arbre la relie directement à Ibrâhîm.",
'ibrahim':"Ibrâhîm est le fils du Prophète ﷺ et de Mâriya al-Qibtiyya selon les récits biographiques. Il meurt alors qu’il est encore nourrisson. Son décès est associé aux traditions rapportant le chagrin du Prophète ﷺ et ses paroles sur la patience face à l’épreuve.",
'hasan':"Al-Hasan est le fils de ʿAlî et de Fâtima, et le petit-fils du Prophète ﷺ. Il occupe ensuite une place importante dans l’histoire de la première communauté musulmane. L’arbre familial relie sa notice à celles de ses parents et de son frère al-Husayn.",
'husayn':"Al-Husayn est le fils de ʿAlî et de Fâtima, et le petit-fils du Prophète ﷺ. Il est tué à Karbalâʾ en 61 H / 680. Son histoire appartient à la période postérieure à la Sîra et doit être distinguée de la chronologie de la vie du Prophète ﷺ présentée dans l’application.",
}
ar={
'fatimah_bint_asad':"فاطمة بنت أسد زوجة أبي طالب، وتذكر الروايات الأسرية أنها أم علي وجعفر. وتنتمي إلى البيت الهاشمي الذي أحاط بالنبي ﷺ في طفولته. وتعرضها شجرة العائلة بوصفها زوجة وأماً، من غير إضافة قصة مستقلة لا تسندها البطاقات الحالية.",
'al_abbas':"العباس بن عبد المطلب عم النبي ﷺ. وتجعله الرواية النسبية جداً للسلالة العباسية اللاحقة. وتظهر صلته بأسرة النبي في شجرة العائلة، أما تفاصيل سيرته فليست مبسوطة في التسلسل الزمني الحالي.",
'safiyyah_bint_abd_al_muttalib':"صفية بنت عبد المطلب عمة النبي ﷺ، وتذكر كتب التراجم أنها أم الزبير بن العوام. وهي من بني هاشم، وتظهر في شجرة العائلة ضمن أبناء عبد المطلب وبناته.",
'al_harith':"الحارث أحد أبناء عبد المطلب، ولذلك يُعد عماً للنبي ﷺ في النسب المشهور. وتساعد ترجمته على إظهار تركيب الأسرة الهاشمية القريبة، ولا تتضمن المصادر المسجلة هنا رواية مفصلة عن حياته.",
'qasim':"القاسم ابن النبي ﷺ وخديجة وفق الرواية السيرية، وقد توفي صغيراً. وترتبط به كنية النبي ﷺ «أبو القاسم». ولا تقدم المصادر المتاحة في التطبيق تفاصيل كثيرة عن حياته القصيرة.",
'zaynab_bint_muhammad':"زينب ابنة النبي ﷺ وخديجة وفق الرواية الأسرية. تزوجت أبا العاص بن الربيع، وكانت أمامة ابنتهما. وتربط سيرتها بين أسرة النبي ﷺ وعلاقات بيوت قريش في السنوات الأولى من الدعوة.",
'ruqayyah':"رقية ابنة النبي ﷺ وخديجة. وتذكر الروايات أنها هاجرت إلى الحبشة مع زوجها عثمان بن عفان. وتربط سيرتها بين بيت النبي ﷺ والهجرات الأولى وتكوّن الجماعة المسلمة خارج مكة.",
'umm_kulthum':"أم كلثوم ابنة النبي ﷺ وخديجة. وتذكر كتب السيرة أنها تزوجت عثمان بن عفان بعد رقية. وتظهر في شجرة العائلة ضمن بنات النبي ﷺ، مع بقاء تفاصيل حياتها أقل حضوراً في البطاقات الحالية.",
'fatimah_bint_muhammad':"فاطمة ابنة النبي ﷺ وخديجة. تزوجت علي بن أبي طالب، وكانت أم الحسن والحسين. وتربطها شجرة العائلة بأكثر من جيل من الأسرة النبوية، ولها مكانة مركزية في الذاكرة الأسرية الإسلامية.",
'abdullah_ibn_muhammad':"عبد الله ابن النبي ﷺ وخديجة وفق الرواية السيرية، وقد توفي صغيراً. وتذكره الروايات ضمن أبناء بيت النبي في مكة، ولا تتوفر في المصادر المسجلة هنا تفاصيل كثيرة عن حياته القصيرة.",
'umama':"أمامة بنت زينب بنت محمد وأبي العاص بن الربيع وفق النسب المشهور، فهي حفيدة النبي ﷺ. وتربط شجرة العائلة ترجمتها مباشرة بترجمتي والديها.",
'abu_al_as':"أبو العاص بن الربيع زوج زينب بنت النبي ﷺ وصهره. وتضعه الروايات السيرية ضمن صلات المصاهرة بين بني هاشم وبيوت قريش. وتربط شجرة العائلة ترجمته بزينب وابنتهما أمامة.",
'sawda':"سودة بنت زمعة إحدى زوجات النبي ﷺ. وتضعها الرواية في بيت النبي بعد وفاة خديجة. وتعرضها الترجمة ضمن أمهات المؤمنين، مع التنبيه إلى أن البطاقات الحالية لا تفصل جميع محطات حياتها.",
'hafsa':"حفصة بنت عمر بن الخطاب إحدى زوجات النبي ﷺ. فهي من أمهات المؤمنين وابنة عمر الذي صار الخليفة الثاني. وينبغي قراءة تفاصيل سيرتها مع الروايات والمراجع الخاصة بكل خبر.",
'umm_salama':"أم سلمة، هند بنت أبي أمية، إحدى زوجات النبي ﷺ. وتذكر الروايات علمها وحسن مشورتها. وترتبط سيرتها بالهجرة الأولى وبحياة الجماعة في المدينة، مع ضرورة نسبة كل خبر إلى مصدره.",
'zaynab_bint_jahsh':"زينب بنت جحش إحدى زوجات النبي ﷺ. وقد ورد ذكر زواجها في القرآن الكريم في الآية 37 من سورة الأحزاب، وهو رابط مباشر بين ترجمتها والنص القرآني. أما بقية التفاصيل فتُقرأ في مصادرها الخاصة.",
'juwayriya':"جويرية بنت الحارث إحدى زوجات النبي ﷺ، وتنسبها الروايات إلى بني المصطلق. وترتبط سيرتها بأخبار هذه القبيلة وما أعقب الغزوة من أحداث، مع مراعاة اختلاف روايات السيرة في التفاصيل.",
'safiyya_bint_huyayy':"صفية بنت حيي إحدى زوجات النبي ﷺ. وتذكر كتب السيرة أنها من أسرة يهودية في خيبر. وترتبط ترجمتها بأحداث شمال الحجاز، وينبغي قراءة أخبار تلك المرحلة مع مقارنة طرق الرواية.",
'umm_habiba':"أم حبيبة رملة بنت أبي سفيان، وهي ابنة أبي سفيان. وتذكر الروايات أنها هاجرت إلى الحبشة قبل زواجها من النبي ﷺ. وتربط سيرتها بين الهجرة الأولى وصلات أسر قريش والجماعة المسلمة.",
'maymuna':"ميمونة بنت الحارث إحدى زوجات النبي ﷺ. وتضع كتب التراجم زواجها في أواخر العهد المدني. وتظهر في شجرة العائلة ضمن أمهات المؤمنين، وتحتاج تفاصيل تاريخ زواجها إلى مراجعة مصادر السيرة.",
'mariya_al_qibtiyya':"مارية القبطية أم إبراهيم ابن النبي ﷺ وفق الرواية السيرية. ويرتبط اسمها بالمرحلة الأخيرة من حياة النبي ﷺ وبولادة إبراهيم ووفاته صغيراً. وتصلها شجرة العائلة بابنها مباشرة.",
'ibrahim':"إبراهيم ابن النبي ﷺ ومارية القبطية وفق الروايات السيرية، وقد توفي رضيعاً. وترتبط وفاته بالأخبار التي تذكر حزن النبي ﷺ وكلامه في الصبر عند المصيبة.",
'hasan':"الحسن ابن علي وفاطمة، وحفيد النبي ﷺ. وكانت له لاحقاً مكانة مهمة في تاريخ الجماعة الإسلامية الأولى. وتربط شجرة العائلة ترجمته بوالديه وبأخيه الحسين.",
'husayn':"الحسين ابن علي وفاطمة، وحفيد النبي ﷺ. قُتل في كربلاء سنة 61 هـ / 680م. وتنتمي سيرته إلى مرحلة لاحقة لحياة النبي ﷺ، ولذلك ينبغي تمييزها عن التسلسل الزمني للسيرة المعروض في التطبيق.",
}
ancestors=['hashim','abd_manaf','qusayy','kilab','murrah','kab','luayy','ghalib','fihr','malik_ancestor','al_nadr','kinana','khuzayma','mudrika','ilyas','mudar','nizar','maadd','adnan']
chain=['adnan','maadd','nizar','mudar','ilyas','mudrika','khuzayma','kinana','al_nadr','malik_ancestor','fihr','ghalib','luayy','kab','murrah','kilab','qusayy','abd_manaf','hashim','abd_al_muttalib','abdullah','muhammad']
parent={b:a for a,b in zip(chain,chain[1:])}
for lang, special in [('fr',fr),('ar',ar)]:
 path=D/f'i18n/{lang}/persons.json'; data=load(path)
 for pid in ancestors:
  if pid not in data: continue
  father=parent.get(pid)
  if lang=='fr':
   if father:
    data[pid]['bio']=f"{data[pid]['name']} est un maillon de la généalogie paternelle traditionnelle de Muhammad ﷺ. Dans la chaîne retenue par l’application, il est présenté comme le parent de {data.get(father,{}).get('name',father)}. Sa notice sert à situer la filiation jusqu’à Adnân ; les sources recensées ici ne fournissent pas un récit détaillé de sa vie."
   else:
    data[pid]['bio']=f"{data[pid]['name']} est le point de départ de la lignée traditionnelle affichée dans l’application, qui remonte ensuite vers Muhammad ﷺ. Les généalogies anciennes divergent sur les chaînes antérieures à Adnân ; l’application ne les présente donc pas comme certaines."
  else:
   if father:
    data[pid]['bio']=f"{data[pid]['name']} حلقة في النسب الأبوي التقليدي لمحمد ﷺ. وتعرضه السلسلة المعتمدة في التطبيق بوصفه والد {data.get(father,{}).get('name',father)}. وتوضح هذه الترجمة موضعه في النسب حتى عدنان، ولا تضيف إليه أحداثاً لا تذكرها المصادر المسجلة."
   else:
    data[pid]['bio']=f"{data[pid]['name']} هو بداية سلسلة النسب التقليدية المعروضة في التطبيق والمتصلة بنسب النبي محمد ﷺ. وتختلف الأنساب القديمة في السلاسل السابقة لعدنان، لذلك لا يعرضها التطبيق على أنها يقينية."
 for pid,text in special.items():
  if pid in data: data[pid]['bio']=text
 save(path,data)
print('Localized and expanded family biographies in French and Arabic.')
