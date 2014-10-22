(* ::Package:: *)

(* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ *)

(* :Title: QEDBhabhaScatteringTree                                          *)

(*
   This software is covered by the GNU Lesser General Public License 3.
   Copyright (C) 1990-2014 Rolf Mertig
   Copyright (C) 1997-2014 Frederik Orellana
   Copyright (C) 2014 Vladyslav Shtabovenko
*)

(* :Summary:  Computation of the matrix element squared for Bhabha
              scattering in QED at tree level                               *)

(* ------------------------------------------------------------------------ *)



(* ::Section:: *)
(*Load FeynCalc, FeynArts and PHI*)


If[ $FrontEnd === Null,
    $FeynCalcStartupMessages = False;
    Print["Computation of the matrix element squared for Bhabha scattering in QED at tree level"];
];
If[$Notebooks === False, $FeynCalcStartupMessages = False];
$LoadTARCER = False;
$LoadPhi =$LoadFeynArts= True;
<<HighEnergyPhysics`FeynCalc`
$FAVerbose = 0;


(* ::Section:: *)
(*Generate Feynman diagrams*)


topBhabha = CreateTopologies[0, 2 -> 2];
diagsBhabha =
  InsertFields[topBhabha, {F[2, {1}], -F[2, {1}]} -> {F[
      2, {1}], -F[2, {1}]}, InsertionLevel -> {Classes},
   Model -> "SM", ExcludeParticles -> {S[1], S[2], V[2]}];
Paint[diagsBhabha, ColumnsXRows -> {2, 1}, Numbering -> None];


(* ::Section:: *)
(*Obtain corresponding amplitudes*)


ampBhabha =
 Map[ReplaceAll[#, FeynAmp[_, _, amp_, ___] :> amp] &,
   Apply[List,
    FCPrepareFAAmp[CreateFeynAmp[diagsBhabha,
     Truncated -> False]]]] //. {(a1__ DiracGamma[6] a2__ +
      a1__ DiracGamma[7] a2__) :> a1 a2, NonCommutative[x___] -> x,
   FermionChain -> DOT,
   FourMomentum[Outgoing, 1] -> k1, FourMomentum[Outgoing, 2] -> k2,
   FourMomentum[Incoming, 1] -> p1, FourMomentum[Incoming, 2] -> p2,
   DiracSpinor -> Spinor,Index[Lorentz, x_] :> LorentzIndex[ToExpression["Lor" <> ToString[x]]]}


(* ::Section:: *)
(*Unpolarized process  e^- e^+ -> e^- e^+ *)


SetMandelstam[s, t, u, p1, p2, -k1, -k2, ME, ME, ME, ME];
sqAmpBhabha =
 (Total[ampBhabha] Total[(ComplexConjugate[ampBhabha]//FCRenameDummyIndices)])//PropagatorDenominatorExplicit//Contract//
    FermionSpinSum[#, ExtraFactor -> 1/2^2, SpinorCollect -> True] & //
    ReplaceAll[#, DiracTrace[x___] :> DiracTrace[x, DiracTraceEvaluate -> True]]&//Contract//Simplify


masslessSqAmpBhabha = (sqAmpBhabha /. {ME -> 0})//Simplify
