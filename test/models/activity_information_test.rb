require "test_helper"

class ActivityInformationTest < ActiveSupport::TestCase
  test "read act information from production details" do
    act = activities(:opening_act)
    ProductionDetail.create!(
      act_id: act.id, executors: "Equipo asignado", notes: "Notas del acto",
      pending_confirmations: "Confirmar proveedor", audio: "Dos micrófonos", screen: "Video de bienvenida"
    )

    assert_equal "Equipo asignado", act.executors
    assert_equal "Notas del acto", act.notes
    assert_equal "Confirmar proveedor", act.pending_confirmations
    assert_equal "Dos micrófonos", act.production_detail.audio
    assert_equal "Video de bienvenida", act.production_detail.screen
  end

  test "handle missing production details" do
    act = activities(:opening_act)

    assert_nil act.executors
    assert_nil act.notes
    assert_nil act.pending_confirmations
    assert_nil act.production_detail
  end

  test "read operation and action information from JSON" do
    [ activities(:reception), activities(:chair_setup) ].each do |activity|
      [ activity.id, activity.source_id ].uniq.each do |id|
        ProductionDetail.create!(act_id: id, executors: "Otro equipo", notes: "Otras notas", audio: "Otro audio")
      end
      activity.update!(details: {
        "executors" => "Equipo propio", "notes" => "Notas propias",
        "pending_confirmations" => "Pendiente propio", "audio" => "Audio propio"
      })

      assert_equal "Equipo propio", activity.executors
      assert_equal "Notas propias", activity.notes
      assert_equal "Pendiente propio", activity.pending_confirmations
      assert_equal "Audio propio", activity.production_detail.audio
    end
  end

  test "separate technical and general information" do
    activity = activities(:reception)
    activity.details = {
      "audio" => "Dos micrófonos", "media_files" => "Lista de reproducción",
      "executors" => "Equipo asignado", "notes" => "Notas generales",
      "pending_confirmations" => "Confirmar horario", "general_questions" => "¿Quién coordina?"
    }

    assert_equal({
      screen: nil, audio: "Dos micrófonos", room_lighting: nil, stage_lighting: nil,
      aisle_lighting: nil, requirements: nil, radios: nil, media_files: "Lista de reproducción"
    }, activity.production_detail.to_h)
    assert_equal "Equipo asignado", activity.executors
    assert_equal "Notas generales", activity.notes
    assert_equal "Confirmar horario", activity.pending_confirmations
    assert_equal "¿Quién coordina?", activity.details.fetch("general_questions")
  end

  test "reflect production changes in fresh instances" do
    act = activities(:opening_act)
    detail = ProductionDetail.create!(act_id: act.id, notes: "Notas iniciales")
    assert_equal "Notas iniciales", act.notes

    detail.update!(notes: "Notas actualizadas")
    assert_equal "Notas actualizadas", Activity.find(act.id).notes

    detail.destroy!
    assert_nil Activity.find(act.id).production_detail
  end
end
