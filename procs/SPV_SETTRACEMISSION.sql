SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_SETTRACEMISSION
-- Paramètre d'entrée	: @v_typeTrace : Type de la trace à écrire
--			  @v_dscTrace : Détail sur le type de trace
--			  @v_idMission : Identifiant de la mission 
--			  @v_idDemande : Identifiant de la demande
--			  @v_typeMission : Type de la mission
--			  @v_priorite : Priorité de la mission
--			  @v_idAgv : Identifiant de l'Agv alloué à la mission
--			  @v_echeance : Date d'échénace de la mission
--			  @v_idCharge : Identifiant de la charge
--			  @v_adrSysExecution : adresse système où a lieu l'action sur la mission 
--			  @v_adrBaseExecution : adresse base où a lieu l'action sur la mission
--			  @v_adrSsBaseExecution : adresse sous base où a lieu l'action sur la mission
--			  @v_adrSysAffinage : adresse système où a lieu l'affinage sur la mission 
--			  @v_adrBaseAffinage : adresse base où a lieu l'affinage sur la mission
--			  @v_adrSsBaseAffinage : adresse sous base où a lieu l'affinage sur la mission
--			  @v_idTache : Identifiant de la tâche
-- Paramètre de sortie	: Code de retour par défaut
--			    - @CODE_OK : L'operation s'est executée correctement
--			    - @CODE_KO_SQL : Une erreur SQL s'est produite lors de l'operation
--			    - @CODE_KO_PARAM : Le type de trace n'est pas connu
-- Descriptif		: Cette procédure permet d'ajouter une trace de mission
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_SETTRACEMISSION]
	@v_typeTrace integer,
	@v_dscTrace varchar(50),
	@v_idMission integer,
	@v_idDemande varchar(20),
	@v_typeMission tinyint,
	@v_priorite int,
	@v_idAgv tinyint,
	@v_echeance dateTime,
	@v_idCharge int,
	@v_adrSysExecution bigint,
	@v_adrBaseExecution bigint,
	@v_adrSsBaseExecution bigint,
	@v_adrSysAffinage bigint,
	@v_adrBaseAffinage bigint,
	@v_adrSsBaseAffinage bigint,
	@v_idTache int,
	@v_ofsProfondeur int,
	@v_ofsNiveau int,
	@v_ofsColonne int
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- déclaration des constantes de code retour 
declare @CODE_OK integer
declare @CODE_KO_SQL integer
declare @CODE_KO_PARAM integer

--définition des constantes de code retour 
set @CODE_OK = 0
set @CODE_KO_SQL = 13
set @CODE_KO_PARAM = 8

-- déclaration des constantes de type de trace mission
declare @CREATION tinyint                 -- Création mission
declare @CHANGE_PRIORITE tinyint          -- Changement de la priorité d'une mission
declare @CHANGE_DATEECHEANCE tinyint      -- Changement de la date d'échéance d'une mission
declare @CHANGE_ETAT tinyint              -- Changement d'état d'une mission
declare @ANNULATION tinyint               -- Annulation d'une mission
declare @FIN tinyint                      -- Fin d'une mission
declare @EXECUTION_TACHE tinyint          -- Exécution d'une tâche mission
declare @DESTRUCTION tinyint			  -- Destruction mission	
declare @AFFINAGE_TACHE tinyint			  -- Affinage d'une tâche mission

-- définition des constantes de type de trace mission
set @CREATION            = 1
set @CHANGE_ETAT         = 2
set @CHANGE_PRIORITE     = 3
set @CHANGE_DATEECHEANCE = 4
set @ANNULATION          = 5
set @FIN                 = 6
set @EXECUTION_TACHE     = 7
set @DESTRUCTION         = 8
set @AFFINAGE_TACHE		 = 20


--déclaration des variables
declare @v_codeRetour integer

-- initialisation des variables
set @v_codeRetour = @CODE_OK

-- controle des types
if      (@v_typeTrace<>@CREATION)
    and (@v_typeTrace<>@CHANGE_ETAT)
    and (@v_typeTrace<>@CHANGE_PRIORITE)
    and (@v_typeTrace<>@CHANGE_DATEECHEANCE)
    and (@v_typeTrace<>@ANNULATION)
    and (@v_typeTrace<>@FIN)
    and (@v_typeTrace<>@EXECUTION_TACHE)
    and (@v_typeTrace<>@AFFINAGE_TACHE)
    and (@v_typeTrace<>@DESTRUCTION)
begin
  set @v_codeRetour = @CODE_KO_PARAM
end


if @v_codeRetour = @CODE_OK
begin
  -- Ecriture des traces de creation
  if (@v_typeTrace = @CREATION)
  begin
    insert into TRACE_MISSION(TMI_Date,TMI_TypeTrc,TMI_IdMission,TMI_IdDemande,TMI_TypeMission,TMI_Priorite,
    TMI_DateEcheance,TMI_IdCharge,TMI_IdAgv,TMI_IDTACHE)
    values (getDate(),@CREATION,@v_idMission,@v_idDemande,@v_typeMission,@v_priorite,@v_echeance,@v_idCharge,@v_idAgv,@v_idTache)
    if @@ERROR <> 0
    begin
      set @v_codeRetour = @CODE_KO_SQL    
    end
  end
  -- Ecriture des traces de destruction mission
  else if (@v_typeTrace = @DESTRUCTION)
  begin
    insert into TRACE_MISSION(TMI_Date,TMI_TypeTrc,TMI_IdMission,TMI_IdDemande)
    values (getDate(),@DESTRUCTION,@v_idMission,@v_idDemande)
    if @@ERROR <> 0
    begin
      set @v_codeRetour = @CODE_KO_SQL    
    end
  end
  else
  begin
    insert into TRACE_MISSION(TMI_Date,TMI_TypeTrc,TMI_DscTrc,TMI_IdMission,TMI_IdDemande,TMI_TypeMission,TMI_Priorite,
    TMI_DateEcheance,TMI_IdCharge,TMI_AdrSys,TMI_AdrBase,TMI_AdrSsBase,TMI_IdAgv,TMI_AFFINAGEADRSYS,TMI_AFFINAGEADRBASE,TMI_AFFINAGEADRSSBASE,TMI_IDTACHE,
    TMI_OFSPROFONDEUR, TMI_OFSNIVEAU, TMI_OFSCOLONNE)
    values (getDate(),@v_typeTrace,@v_dscTrace,@v_idMission,@v_idDemande,@v_typeMission,@v_priorite,@v_echeance,@v_idCharge,
    @v_adrSysExecution,@v_adrBaseExecution,@v_adrSsBaseExecution,@v_idAgv,
    @v_adrSysAffinage,@v_adrBaseAffinage,@v_adrSsBaseAffinage,@v_idTache,@v_ofsProfondeur,@v_ofsNiveau,@v_ofsColonne)
    if @@ERROR <> 0
    begin
      set @v_codeRetour = @CODE_KO_SQL    
    end
  end
end


return @v_codeRetour 		



