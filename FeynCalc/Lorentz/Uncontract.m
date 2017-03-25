(* ::Package:: *)

(* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ *)

(* :Title: Uncontract														*)

(*
	This software is covered by the GNU General Public License 3.
	Copyright (C) 1990-2016 Rolf Mertig
	Copyright (C) 1997-2016 Frederik Orellana
	Copyright (C) 2014-2016 Vladyslav Shtabovenko
*)

(* :Summary:  Uncontracts Lorentz and Cartesian tensors						*)

(* ------------------------------------------------------------------------ *)

Uncontract::usage = "Uncontract[exp,q1,q2, ...] uncontracts Eps \
and DiracGamma. Uncontract[exp,q1,q2, Pair->{p}] uncontracts \
also p.q1 and p.q2; Pair -> All uncontracts all except \
OPEDelta. Dimension -> Automatic leaves dimensions unchanged.";

Uncontract::failmsg =
"Error! Uncontract has encountered a fatal problem and must abort the computation. \
The problem reads: `1`"

(* ------------------------------------------------------------------------ *)

Begin["`Package`"]
End[]

Begin["`Uncontract`Private`"]

ucVerbose::usage="";
dim::usage="";

Options[Uncontract] = {
	CMomentum -> True,
	CPair -> {},
	Dimension -> Automatic,
	DiracGamma -> True,
	PauliSigma -> True,
	DotSimplify -> True,
	Eps -> True,
	FCE -> False,
	FCI -> False,
	FCTensor -> All,
	FCVerbose -> False,
	Momentum -> True,
	Pair -> {},
	Polarization -> True,
	Square -> True
};

Uncontract[x_List, q__] :=
	Map[Uncontract[#,q]&, x];

Uncontract[x_, q1__, q2:Except[_?OptionQ], opts:OptionsPattern[]] :=
	Uncontract[Uncontract[x,q2,opts],q1, opts];

Uncontract[ex_, All, opts:OptionsPattern[]] :=
	Block[{exp,moms,null1,null2,res},

		If [OptionValue[FCVerbose]===False,
			ucVerbose=$VeryVerbose,
			If[MatchQ[OptionValue[FCVerbose], _Integer?Positive | 0],
				ucVerbose=OptionValue[FCVerbose]
			];
		];

		FCPrint[1, "Uncontract: Entering Uncontract for all momenta.", FCDoControl->ucVerbose];

		If[ OptionValue[FCI],
			exp = ex,
			exp = FCI[ex]
		];
		moms = Cases[(exp + null1+null2)/. _FeynAmpDenominator :> Unique[], (Momentum | CMomentum)[z_, ___] :> z, Infinity] // DeleteDuplicates // Sort;
		FCPrint[1, "Uncontract: List of momenta:", moms , FCDoControl->ucVerbose];

		If[	moms=!={},
			res = Uncontract[exp, Sequence@@moms, FCI->True ,opts],
			res = exp
		];

		FCPrint[1, "Uncontract: Leaving Uncontract for all momenta.", FCDoControl->ucVerbose];

		res

	];


Uncontract[ex_, q:Except[_?OptionQ], OptionsPattern[]] :=
	Block[{	exp,li, li2, pairs, cpairs, times,null1,null2,
			allObjects, selectedObjects,dotTimes,
			momAllow, cmomAllow,
			epsRules={}, digaRules={}, sigmaRules={}, pairRules={}, cpairRules={},
			repRuleObjects = {}, res, uniqueHead, qRule,
			tensorList, tensorRules = {},
			alternativesTensorList, tensoruncontract, fctensor,qMark
		},

		If [OptionValue[FCVerbose]===False,
			ucVerbose=$VeryVerbose,
			If[MatchQ[OptionValue[FCVerbose], _Integer?Positive | 0],
				ucVerbose=OptionValue[FCVerbose]
			];
		];

		FCPrint[1, "Uncontract: Entering Uncontract", FCDoControl->ucVerbose];
		FCPrint[3, "Uncontract: Entering with, ", ex , FCDoControl->ucVerbose];
		FCPrint[3, "Uncontract: q: ", q , FCDoControl->ucVerbose];

		pairs = OptionValue[Pair];
		cpairs = OptionValue[CPair];
		dim = OptionValue[Dimension];
		fctensor = OptionValue[FCTensor];

		momAllow = OptionValue[Momentum];
		cmomAllow = OptionValue[CMomentum];
		Which[	fctensor===All,
					tensoruncontract=True;
					tensorList = Complement[$FCTensorList, {CPair, Pair, Eps}],
				Head[fctensor]===List && fctensor=!={},
					tensoruncontract=True;
					tensorList = fctensor,
				True,
					tensoruncontract = False;
					tensorList = {}
		];


		If[	Length[tensorList] > 1,
			alternativesTensorList = Alternatives@@(Blank/@tensorList),
			If[ tensorList==={},
				alternativesTensorList = Null,
				alternativesTensorList = Blank[(Identity@@tensorList)]
			]
		];


		qRule = q :> qMark[q];


		If[	momAllow,

			pairRules = Join[pairRules, {Pair[Momentum[arg_,di_:4], Momentum[pe_, dim2_:4]]/;!FreeQ[arg,qMark] && FreeQ[pe,qMark] :>
			(	li = LorentzIndex[$AL[Unique[]],dimSelectLorentz[di]];
			Pair[Momentum[arg, dimSelectLorentz[di]],li] Pair[li, Momentum[pe,dimSelectLorentz[dim2]] ]),

			Pair[Momentum[arg_,di_:4], Momentum[pe_, di_:4]]/;!FreeQ[arg,qMark] && !FreeQ[pe,qMark] :>
			(	li = LorentzIndex[$AL[Unique[]],dimSelectLorentz[di]];
				li2 = LorentzIndex[$AL[Unique[]],dimSelectLorentz[di]];
				Pair[li, li2] Pair[Momentum[arg, dimSelectLorentz[di]],li] Pair[li2, Momentum[pe,dimSelectLorentz[di]]])

			}];

			epsRules = Join[epsRules,
				{Eps[a___, Momentum[arg_,di_:4]  ,b___]/;!FreeQ[arg,qMark] :>
				(	li = LorentzIndex[$AL[Unique[]],dimSelectLorentz[di]];
				Pair[Momentum[arg, dimSelectLorentz[di]],li]Eps[a,li,b])
			}];

			digaRules = Join[digaRules,
				{DiracGamma[Momentum[arg_,di_:4],di_:4]/;!FreeQ[arg,qMark] :>
				(	li = LorentzIndex[$AL[Unique[]],dimSelectLorentz[di]];
				Pair[Momentum[arg, dimSelectLorentz[di]],li] DiracGamma[li,dimSelectLorentz[di]])
			}];

			sigmaRules = Join[sigmaRules,
				{PauliSigma[Momentum[arg_,di1_:4],di2_:3]/;!FreeQ[arg,qMark] :>
				(	li = LorentzIndex[$AL[Unique[]],dimSelectLorentz[di1]];
				Pair[Momentum[arg, dimSelectLorentz[di1]],li] PauliSigma[li,dimSelectCartesian[di2]])
			}];

			tensorRules = Join[tensorRules,
				{(hd_/;MemberQ[tensorList,hd])[a___, Momentum[arg_,di_:4]  ,b___]/;!FreeQ[arg,qMark] :>
				(	li = LorentzIndex[$AL[Unique[]],dimSelectLorentz[di]];
				Pair[Momentum[arg, dimSelectLorentz[di]],li] hd[a,li,b])
			}];

		];

		If[	cmomAllow,

			pairRules = Join[pairRules, {Pair[CMomentum[arg_,di_:3], LorentzIndex[pe_, dim2_:4]]/;!FreeQ[arg,qMark] :>
			(	li = CIndex[$AL[Unique[]],dimSelectCartesian[di]];
			CPair[CMomentum[arg, dimSelectCartesian[di]],li] Pair[li, LorentzIndex[pe,dimSelectLorentz[dim2]] ])
			}];


			cpairRules = Join[cpairRules, {CPair[CMomentum[arg_,di_:3], CMomentum[pe_, di_:3]]/;!FreeQ[arg,qMark] && FreeQ[pe,qMark] :>
			(	li = CIndex[$AL[Unique[]],dimSelectCartesian[di]];
			CPair[CMomentum[arg, dimSelectCartesian[di]],li] CPair[li, CMomentum[pe,dimSelectCartesian[di]] ]),

			CPair[CMomentum[arg_,di_:3], CMomentum[pe_, di_:3]]/;!FreeQ[arg,qMark] && !FreeQ[pe,qMark] :>
			(	li = CIndex[$AL[Unique[]],dimSelectCartesian[di]];
				li2 = CIndex[$AL[Unique[]],dimSelectCartesian[di]];
			CPair[li,li2] CPair[CMomentum[arg, dimSelectCartesian[di]],li] CPair[li2, CMomentum[pe,dimSelectCartesian[di]] ])
			}];

			epsRules = Join[epsRules,{Eps[a___, CMomentum[arg_,di_:3]  ,b___]/;!FreeQ[arg,qMark] :>
			(	li = CIndex[$AL[Unique[]],dimSelectCartesian[di]];
				CPair[CMomentum[arg, dimSelectCartesian[di]],li]Eps[a,li,b])
			}];

			digaRules = Join[digaRules,
				{DiracGamma[CMomentum[arg_]]/;!FreeQ[arg,qMark] :>
				(	li = CIndex[$AL[Unique[]],dimSelectCartesian[3]];
				CPair[CMomentum[arg, dimSelectCartesian[3]],li] DiracGamma[li,dimSelectLorentz[4]]),


				DiracGamma[CMomentum[arg_,di_Symbol-1],di_Symbol]/;!FreeQ[arg,qMark] :>
					(	li = CIndex[$AL[Unique[]],dimSelectCartesian[di-1]];
						CPair[CMomentum[arg, dimSelectCartesian[di-1]],li] DiracGamma[li,dimSelectLorentz[di]]),

				DiracGamma[CMomentum[arg_,di_Symbol-4],di_Symbol-4]/;!FreeQ[arg,qMark] :>
					(	li = CIndex[$AL[Unique[]],dimSelectCartesian[di-4]];
						CPair[CMomentum[arg, dimSelectCartesian[di-4]],li] DiracGamma[li,dimSelectLorentz[di-4]])
			}];

			sigmaRules = Join[sigmaRules, {PauliSigma[CMomentum[arg_,di_:3],di_:3]/;!FreeQ[arg,qMark] :>
			(	li = CIndex[$AL[Unique[]],dimSelectCartesian[di]];
			CPair[CMomentum[arg, dimSelectCartesian[di]],li] PauliSigma[li, dimSelectCartesian[di]])
			}];

			tensorRules = Join[tensorRules,{(hd_/;MemberQ[tensorList,hd])[a___, CMomentum[arg_,di_:3]  ,b___]/;!FreeQ[arg,qMark] :>
			(	li = CIndex[$AL[Unique[]],dimSelectCartesian[di]];
				CPair[CMomentum[arg, dimSelectCartesian[di]],li]hd[a,li,b])
			}];


		];

		If[ OptionValue[FCI],
			exp = ex,
			exp = FCI[ex]
		];

		FCPrint[1, "Uncontract: Applying Expand2 and ExpandScalarProduct", FCDoControl->ucVerbose];
		exp = Expand2[ExpandScalarProduct[exp,Momentum->{q}],q];
		FCPrint[1, "Uncontract: Done applying Expand2 and ExpandScalarProduct", FCDoControl->ucVerbose];
		FCPrint[3, "Uncontract: After Expand2 and ExpandScalarProduct: ", exp, FCDoControl->ucVerbose];

		(* Select suitable Pairs *)
		If[pairs=!={},
			FCPrint[1, "Uncontract: Uncontracting Pair objects.", FCDoControl->ucVerbose];
			(* now all q's are marked with qMark *)
			exp = powerExpand[exp, q, Pair, times];
			allObjects = Cases[exp + null1 + null2, _Pair, Infinity]//DeleteDuplicates//Sort;
			Which[	pairs===All,
						selectedObjects = allObjects,
					Head[pairs]===List,
						selectedObjects = SelectNotFree[SelectNotFree[allObjects, q], pairs],
					True,
						Message[Uncontract::failmsg,"Unknown Pair input"];
						Abort[]
			];
			selectedObjects = SelectFree[selectedObjects, OPEDelta];
			If[ !OptionValue[Polarization],
				selectedObjects = SelectFree[selectedObjects, Polarization];
			];
			(* do not uncontract momenta squared *)
			If[ !OptionValue[Square],
				selectedObjects = selectedObjects /. Pair[zx_, zy_]/; !FreeQ[zx,q] && !FreeQ[zy,q] :> Unevaluated[Sequence[]]
			];
			repRuleObjects = Thread[Rule[selectedObjects,(selectedObjects/.qRule)]];
			FCPrint[3, "Uncontract: List pairs objects that should be uncontracted: ", repRuleObjects, FCDoControl->ucVerbose];
			exp = exp /. repRuleObjects;
			(* now qMark marks only Pairs that should be uncontracted *)
			FCPrint[3, "Uncontract: Replacement rule for Pairs: ", pairRules , FCDoControl->ucVerbose];
			exp = exp //. pairRules  /. qMark -> Identity;
			FCPrint[3, "Uncontract: After applying the replacement rule for Pairs: ", exp , FCDoControl->ucVerbose]
		];

		(* Select suitable CPairs *)
		If[cpairs=!={},
			FCPrint[1, "Uncontract: Uncontracting CPair objects.", FCDoControl->ucVerbose];
			exp = powerExpand[exp, q, CPair, times];
			allObjects = Cases[exp + null1 + null2, _CPair, Infinity]//DeleteDuplicates//Sort;
			Which[	cpairs===All,
						selectedObjects = allObjects,
					Head[cpairs]===List,
						selectedObjects = SelectNotFree[SelectNotFree[allObjects, q], cpairs],
					True,
						Message[Uncontract::failmsg,"Unknown CPair input"];
						Abort[]
			];
			selectedObjects = SelectFree[selectedObjects, OPEDelta];
			If[ !OptionValue[Polarization],
				selectedObjects = SelectFree[selectedObjects, Polarization];
			];
			If[ !OptionValue[Square],
				(* do not uncontract momenta squared *)
				selectedObjects = selectedObjects /. CPair[zx_, zy_]/; !FreeQ[zx,q] && !FreeQ[zy,q] :> Unevaluated[Sequence[]]
			];
			repRuleObjects = Thread[Rule[selectedObjects,(selectedObjects/.qRule)]];
			FCPrint[3, "Uncontract: List pairs objects that should be uncontracted: ", repRuleObjects, FCDoControl->ucVerbose];
			exp = exp /. repRuleObjects;
			(* now qMark marks only CPairs that should be uncontracted *)
			FCPrint[3, "Uncontract: Replacement rule for CPairs: ", cpairRules , FCDoControl->ucVerbose];
			exp = exp //. cpairRules  /. qMark -> Identity;
			FCPrint[3, "Uncontract: After applying the replacement rule for CPairs: ", exp , FCDoControl->ucVerbose]
		];

		(* Select suitable DiracGammas *)
		If[	!FreeQ[exp,DiracGamma] && OptionValue[DiracGamma],
			FCPrint[1, "Uncontract: Uncontracting DiracGamma objects.", FCDoControl->ucVerbose];
			exp = powerExpand[exp, q, DiracGamma, dotTimes] /. qRule;
			allObjects = Cases[exp + null1 + null2, _DiracGamma, Infinity]//DeleteDuplicates//Sort;
			selectedObjects = SelectNotFree[allObjects, q];
			If[ !OptionValue[Polarization],
				selectedObjects = SelectFree[selectedObjects, Polarization];
			];
			repRuleObjects = Thread[Rule[selectedObjects,(DiracGammaExpand[selectedObjects,FCI->True,Momentum->{q}]/.qRule)]];
			FCPrint[3, "Uncontract: List DiracGamma objects that should be uncontracted: ", repRuleObjects, FCDoControl->ucVerbose];
			exp = exp /. repRuleObjects;
			(* now qMark marks only DiracGammas that should be uncontracted *)
			FCPrint[3, "Uncontract: Replacement rule for DiracGamma: ", digaRules , FCDoControl->ucVerbose];
			exp = exp //. digaRules /. qMark -> Identity;
			FCPrint[3, "Uncontract: After applying the replacement rule for DiracGamma: ", exp , FCDoControl->ucVerbose]
		];

		(* Select suitable PaulSigmas *)
		If[	!FreeQ[exp,PauliSigma] && OptionValue[PauliSigma],
			FCPrint[1, "Uncontract: Uncontracting PauliSigma objects.", FCDoControl->ucVerbose];
			exp = powerExpand[exp, q, PauliSigma, dotTimes] /. qRule;
			allObjects = Cases[exp + null1 + null2, _PauliSigma, Infinity]//DeleteDuplicates//Sort;
			selectedObjects = SelectNotFree[allObjects, q];
			If[ !OptionValue[Polarization],
				selectedObjects = SelectFree[selectedObjects, Polarization];
			];
			repRuleObjects = Thread[Rule[selectedObjects,(PauliSigmaExpand[selectedObjects,FCI->True,Momentum->{q}]/.qRule)]];
			FCPrint[3, "Uncontract: List PauliSigma objects that should be uncontracted: ", repRuleObjects, FCDoControl->ucVerbose];
			exp = exp /. repRuleObjects;
			(* now qMark marks only PauliSigmas that should be uncontracted *)
			FCPrint[3, "Uncontract: Replacement rule for PauliSigma: ", sigmaRules , FCDoControl->ucVerbose];
			exp = exp //. sigmaRules  /. qMark -> Identity;
			FCPrint[3, "Uncontract: After applying the replacement rule for PauliSigma: ", exp , FCDoControl->ucVerbose]
		];

		(* Select suitable Eps tensors *)
		If[	!FreeQ[exp,Eps] && OptionValue[Eps],
			FCPrint[1, "Uncontract: Uncontracting Eps objects.", FCDoControl->ucVerbose];
			exp = EpsEvaluate[exp,FCI->True,Momentum->{q}];
			exp = powerExpand[exp, q, Eps, times] /. qRule;
			allObjects = Cases[exp + null1 + null2, _Eps, Infinity]//DeleteDuplicates//Sort;
			selectedObjects = SelectNotFree[allObjects, q];
			If[ !OptionValue[Polarization],
				selectedObjects = SelectFree[selectedObjects, Polarization];
			];
			repRuleObjects = Thread[Rule[selectedObjects,(selectedObjects/.qRule)]];
			FCPrint[3, "Uncontract: List Eps objects that should be uncontracted: ", repRuleObjects, FCDoControl->ucVerbose];
			exp = exp /. repRuleObjects;
			(* now qMark marks only Eps tensors that should be uncontracted *)
			FCPrint[3, "Uncontract: Replacement rule for Eps tensors: ", epsRules , FCDoControl->ucVerbose];
			exp = exp //. epsRules  /. qMark -> Identity;
			FCPrint[3, "Uncontract: After applying the replacement rule for Eps tensors: ", exp , FCDoControl->ucVerbose]
		];

		(* Select possibly remaining tensors *)
		If[	!FreeQ2[exp,tensorList]  && tensoruncontract,
			FCPrint[1, "Uncontract: Uncontracting tensors: ", tensorList , FCDoControl->ucVerbose];
			exp = Fold[powerExpand[#1, q, #2, times] &, exp, tensorList] /. qRule;
			allObjects = Cases[exp + null1 + null2, alternativesTensorList , Infinity]//DeleteDuplicates//Sort;
			selectedObjects = SelectNotFree[allObjects, q];
			If[ !OptionValue[Polarization],
				selectedObjects = SelectFree[selectedObjects, Polarization];
			];

			repRuleObjects = Thread[Rule[selectedObjects,(selectedObjects/.qRule)]];
			FCPrint[3, "Uncontract: List of other tensors that should be uncontracted: ", repRuleObjects, FCDoControl->ucVerbose];
			exp = exp /. repRuleObjects;
			(* now qMark marks only Eps tensors that should be uncontracted *)
			FCPrint[3, "Uncontract: Replacement rule for other tensors: ", tensorRules , FCDoControl->ucVerbose];
			exp = exp //. tensorRules /. qMark -> Identity;
			FCPrint[3, "Uncontract: After applying the replacement rule for other tensors: ", exp , FCDoControl->ucVerbose]
		];
		res = exp /. times -> Times /. dotTimes -> DOT;

		FCPrint[1, "Uncontract: Intermediate result: " ,res, FCDoControl->ucVerbose];

		If[	OptionValue[DotSimplify] && !FreeQ2[res,{DiracGamma,PauliSigma}],
			res = DotSimplify[res,Expanding -> False, FCI->False];
		];

		If[	OptionValue[FCE],
			res = FCE[res]
		];

		res

	]/; q=!=All;

powerExpand[ex_, q_, head_, times_]:=
	ex /. Power[Pattern[z,Blank[head]], n_Integer?Positive]/;!FreeQ[z,q] :>
		Apply[times, Table[z, {Abs[n]}]]^Sign[n]/; !FreeQ[ex,Power];

powerExpand[ex_, _, _, _]:=
	ex/; FreeQ[ex,Power];

dimSelectCartesian[z_]:=
	If[ dim===Automatic,
		z,
		Switch[
			dim,
			4,
				3,
			_Symbol,
				dim - 1,
			_Symbol - 4,
				dim,
			_,
			Message[Uncontract::failmsg, "Unsupported dimension!"];
			Abort[]
		]
	];

dimSelectLorentz[z_]:=
	If[ dim===Automatic,
		z,
		dim
	];

FCPrint[1,"Uncontract.m loaded."];
End[]
